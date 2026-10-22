using MaiHaThanhVy_Backend.Data;
using MaiHaThanhVy_Backend.Models;
using Microsoft.EntityFrameworkCore;

var connection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? throw new InvalidOperationException("Missing ConnectionStrings__DefaultConnection.");

string GetEmail(string name, string fallback)
{
    var value = Environment.GetEnvironmentVariable(name)?.Trim().ToLowerInvariant();
    return string.IsNullOrEmpty(value) ? fallback : value;
}

var adminEmail = GetEmail("DEMO_ADMIN_EMAIL", "admin@example.com");
var teacherEmail = GetEmail("DEMO_TEACHER_EMAIL", "teacher1@example.com");
var studentEmail = GetEmail("DEMO_STUDENT_EMAIL", "student1@example.com");

if (new[] { adminEmail, teacherEmail, studentEmail }.Distinct().Count() != 3)
{
    throw new InvalidOperationException("Demo account emails must be distinct.");
}

var options = new DbContextOptionsBuilder<AppDbContext>()
    .UseSqlServer(connection, sql => sql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName))
    .Options;

await using var db = new AppDbContext(options);
await db.Database.MigrateAsync();
await using var transaction = await db.Database.BeginTransactionAsync();

async Task<User> EnsureUser(string email, string name, string role, string password)
{
    var user = await db.Users.SingleOrDefaultAsync(x => x.Email == email);
    if (user is null)
    {
        user = new User
        {
            Email = email,
            FullName = name,
            Role = role,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            IsActive = true,
            IsEmailVerified = true,
            CreatedAt = DateTime.UtcNow
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        Console.WriteLine($"Created {role}: {email}");
    }
    else if (user.Role != role)
    {
        throw new InvalidOperationException($"Existing account {email} has role {user.Role}, expected {role}.");
    }
    else
    {
        Console.WriteLine($"Kept existing {role}: {email} (password unchanged)");
    }
    return user;
}

await EnsureUser(adminEmail, "Quản trị viên Demo", "ADMIN", "AdminPassword123@");
var teacherUser = await EnsureUser(teacherEmail, "Giảng viên Demo", "TEACHER", "Password123@");
var studentUser = await EnsureUser(studentEmail, "Sinh viên Demo", "STUDENT", "Password123@");

var teacher = await db.Teachers.SingleOrDefaultAsync(x => x.Email == teacherEmail);
if (teacher is null)
{
    teacher = new Teacher
    {
        TeacherCode = "GVDEMO001",
        FullName = teacherUser.FullName,
        Email = teacherEmail,
        Department = "Công nghệ thông tin",
        UserId = teacherUser.Id,
        IsActive = true
    };
    db.Teachers.Add(teacher);
    await db.SaveChangesAsync();
}
else if (teacher.UserId != teacherUser.Id)
{
    throw new InvalidOperationException($"Teacher profile {teacherEmail} belongs to another user.");
}

var student = await db.Students.SingleOrDefaultAsync(x => x.Email == studentEmail);
if (student is null)
{
    student = new Student
    {
        StudentCode = "SVDEMO001",
        FullName = studentUser.FullName,
        Email = studentEmail,
        Major = "Công nghệ thông tin",
        UserId = studentUser.Id,
        IsActive = true
    };
    db.Students.Add(student);
    await db.SaveChangesAsync();
}
else if (student.UserId != studentUser.Id)
{
    throw new InvalidOperationException($"Student profile {studentEmail} belongs to another user.");
}

var subject = await db.Subjects.SingleOrDefaultAsync(x => x.SubjectCode == "DEMO101");
if (subject is null)
{
    subject = new Subject
    {
        SubjectCode = "DEMO101",
        SubjectName = "Lập trình di động",
        Credits = 3,
        Description = "Môn học mẫu cho clip demo",
        IsActive = true
    };
    db.Subjects.Add(subject);
    await db.SaveChangesAsync();
}

var classroom = await db.ClassRooms.SingleOrDefaultAsync(x => x.ClassName == "LTDD-DEMO-01");
if (classroom is null)
{
    classroom = new ClassRoom
    {
        ClassName = "LTDD-DEMO-01",
        SubjectId = subject.Id,
        TeacherId = teacher.Id,
        Room = "A101",
        Semester = "2026-2027-1",
        Schedule = "Thứ 2 08:00-11:30",
        MaxStudents = 40,
        IsActive = true
    };
    db.ClassRooms.Add(classroom);
    await db.SaveChangesAsync();
}
else if (classroom.SubjectId != subject.Id || classroom.TeacherId != teacher.Id)
{
    throw new InvalidOperationException("Existing LTDD-DEMO-01 class has a different subject or teacher.");
}

var enrollment = await db.ClassEnrollments.SingleOrDefaultAsync(
    x => x.ClassRoomId == classroom.Id && x.StudentId == student.Id);
if (enrollment is null)
{
    db.ClassEnrollments.Add(new ClassEnrollment
    {
        ClassRoomId = classroom.Id,
        StudentId = student.Id,
        IsActive = true
    });
}
else
{
    enrollment.IsActive = true;
}

await db.SaveChangesAsync();
await transaction.CommitAsync();
Console.WriteLine($"Demo database ready: class {classroom.ClassName}, teacher ID {teacher.Id}, student ID {student.Id}.");
Console.WriteLine("Login still requires a working SMTP configuration and access to each account's email inbox.");
