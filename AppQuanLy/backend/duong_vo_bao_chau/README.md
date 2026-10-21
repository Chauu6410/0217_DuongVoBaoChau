# App quản lý điện thoại trẻ em

ASP.NET Core 8 Web API, ASP.NET Core Identity, EF Core và SQL Server.
Code sử dụng controller và DbContext trực tiếp theo kiểu bài Lab.

## Các file chính

- `duong_vo_bao_chau/Models/User.cs`: kế thừa IdentityUser, thêm FullName.
- `duong_vo_bao_chau/Models/Device.cs`: thiết bị và UserId của chủ sở hữu.
- `duong_vo_bao_chau/Models/RegisterModel.cs`, `LoginModel.cs`: dữ liệu đăng ký, đăng nhập.
- `duong_vo_bao_chau/Data/ApplicationDbContext.cs`: IdentityDbContext và bảng Devices.
- `duong_vo_bao_chau/Controllers/AuthenticateController.cs`: đăng ký, gán role, xác thực mật khẩu và OTP, tạo JWT.
- `duong_vo_bao_chau/Controllers/DeviceController.cs`: CRUD bằng EF Core.
- `duong_vo_bao_chau/Program.cs`: Identity, SQL Server, JWT, CORS, Swagger và tạo role.

## Chạy trong Visual Studio 2022

1. Mở `duong_vo_bao_chau.sln`, chọn project Web API làm Startup Project.
2. Restore NuGet packages. Các package Microsoft đang dùng phiên bản 8.0.21.
3. Sửa `ConnectionStrings:DefaultConnection` trong `appsettings.json` theo SQL Server của bạn. Mặc định dùng LocalDB của Visual Studio:

```json
"DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=ChildPhoneDb;Trusted_Connection=True;TrustServerCertificate=True"
```

Nếu dùng SQL Server Express, đổi Server thành `.\\SQLEXPRESS` trong JSON.

4. Mở **Tools > NuGet Package Manager > Package Manager Console**, chọn Default project là `duong_vo_bao_chau`, chạy:

```powershell
Add-Migration InitialCreate
Update-Database
```

Chỉ chạy Add-Migration InitialCreate lần đầu. Khi thay đổi model, tạo migration với tên mới rồi chạy Update-Database.

5. Chạy bằng F5 trong môi trường Development, mở `/swagger`. Khi khởi động, chương trình tạo ba role Admin, Staff, Parent nếu chưa có. Database cần được tạo ở bước 4 trước khi chạy.

JWT dùng khóa mẫu trong `appsettings.Development.json` để chạy Lab. Khi triển khai, cung cấp khóa bí mật riêng ít nhất 32 byte qua cấu hình `Jwt:Key` (ví dụ biến môi trường `Jwt__Key`). `Jwt:Issuer` và `Jwt:Audience` đã có trong `appsettings.json`.

CORS cho phép `http://localhost:3000` và `http://localhost:5173`. Sửa `Cors:AllowedOrigins` nếu frontend dùng địa chỉ khác.

## Đăng ký

Gọi `POST /api/Authenticate/register`:

```json
{
  "email": "parent@example.com",
  "password": "Parent@123",
  "fullName": "Nguyễn Văn A",
  "role": "Parent"
}
```

Mật khẩu theo mặc định Identity: ít nhất 6 ký tự, có chữ hoa, chữ thường, chữ số và ký tự đặc biệt. Email chính là Username.

API trả `status`, `id`, `username`, `role`. Không cần cài ứng dụng Authenticator.

Trong Development, có thể chọn cả ba role để thử bài Lab. Ngoài Development, đăng ký công khai chỉ chấp nhận Parent để tránh tự cấp quyền Admin/Staff. Việc cấp quyền quản trị ở môi trường triển khai cần quy trình quản trị riêng.

## Lấy OTP (Cách 2)

Gọi `POST /api/Authenticate/generate-otp`:

```json
{
  "username": "parent@example.com",
  "password": "Parent@123"
}
```

API kiểm tra tài khoản, mật khẩu rồi sinh mã ngẫu nhiên 6 chữ số và trả trực tiếp:

```json
{
  "status": true,
  "otp": "654321"
}
```

OTP lưu bằng IMemoryCache theo UserId, có hạn 5 phút. Sinh mã mới thay thế mã cũ của cùng tài khoản. Khởi động lại API sẽ mất các OTP đang lưu. Đây là cách mô phỏng OTP cho bài Lab; trả mã ngay trong JSON không tạo thêm yếu tố xác thực độc lập. Ứng dụng thực tế nên chuyển mã qua email/SMS.

## Đăng nhập

Gọi `POST /api/Authenticate/login`:

```json
{
  "username": "parent@example.com",
  "password": "Parent@123",
  "otpCode": "123456"
}
```

Thay `123456` bằng mã từ API generate-otp, dùng cùng username. Backend so sánh với OTP đã lưu, không nhận mã đối chiếu từ client. Mã hết hạn hoặc chưa được sinh sẽ bị từ chối. Sau khi đăng nhập thành công, OTP bị xóa; lần tiếp theo phải lấy mã mới. Kết quả chứa `token`, `expiration` (UTC). JWT hết hạn sau 60 phút, chứa Username, Role, UserId cùng các claim chuẩn cho phân quyền. Sai mật khẩu hoặc OTP 5 lần sẽ khóa tài khoản 5 phút.

Thay đổi OTP này không thay đổi cấu trúc database, không cần tạo migration mới nếu đã có database từ phiên bản trước. Tài khoản đã đăng ký vẫn dùng được.

Nhấn **Authorize** trong Swagger, nhập token. Khi gọi bằng Postman/frontend, gửi header:

```http
Authorization: Bearer <token>
```

## CRUD thiết bị

| Phương thức | URL | Action |
| --- | --- | --- |
| GET | /api/Device | GetDevices |
| GET | /api/Device/1 | GetDeviceById |
| POST | /api/Device | AddDevice |
| PUT | /api/Device/1 | UpdateDevice |
| DELETE | /api/Device/1 | DeleteDevice |

Body thêm thiết bị (thay userId bằng id từ kết quả đăng ký):

```json
{
  "deviceName": "Điện thoại của con",
  "macAddress": "AA:BB:CC:DD:EE:FF",
  "batteryLevel": 85,
  "isLocked": false,
  "userId": "ID_TAI_KHOAN"
}
```

Khi PUT, gửi toàn bộ dữ liệu như trên và thêm `"id": 1` khớp URL. BatteryLevel nhận 0–100. Parent chỉ đọc/thêm/sửa/xóa thiết bị của mình; Admin và Staff quản lý tất cả. UserId phải tồn tại. Thiết bị không tồn tại hoặc ngoài phạm vi truy cập trả 404; thêm thành công trả 201; sửa/xóa thành công trả 204.

IsLocked chỉ là trạng thái lưu trong database. Để khóa điện thoại thật, cần ứng dụng phía thiết bị nhận và thực thi lệnh.

## Kiểm tra

Đã chạy `dotnet build`: thành công, không có warning/error. Chưa chạy migration hoặc kiểm thử API với SQL Server; thực hiện các bước trên để kiểm tra trên database của bạn.

Tham khảo: https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-8.0

## Chia sẻ vị trí thiết bị

Đã có migration `AddDeviceLocation`. Trong Package Manager Console chạy `Update-Database` (không tạo lại migration này), sau đó khởi động lại API.

Hai API yêu cầu JWT. Parent chỉ truy cập thiết bị của mình; Admin và Staff truy cập tất cả. Thiết bị không tồn tại hoặc ngoài phạm vi truy cập trả 404.

Gọi `POST /api/Device/update-location`:

```json
{
  "deviceId": 1,
  "latitude": 10.7769,
  "longitude": 106.7009
}
```

Cả ba trường đều bắt buộc. DeviceId phải lớn hơn 0; Latitude từ -90 đến 90, Longitude từ -180 đến 180. Dữ liệu không hợp lệ trả 400. Server ghi `LastUpdatedLocation` bằng thời gian UTC hiện tại và trả 200 cùng vị trí đã cập nhật.

Gọi `GET /api/Device/1/location` để nhận:

```json
{
  "latitude": 10.7769,
  "longitude": 106.7009,
  "lastUpdatedLocation": "2026-10-22T03:00:00"
}
```

Thời gian ví dụ và thời gian trả về đều được hiểu là UTC (SQL Server datetime2 không lưu múi giờ). Thiết bị chưa cập nhật vị trí trả 200 với ba trường null; frontend cần kiểm tra null trước khi đặt marker trên bản đồ. Thêm thiết bị sẽ để vị trí null; sửa thông tin thiết bị không làm thay đổi vị trí. Chỉ API update-location cập nhật tọa độ và thời gian.

Backend lưu vị trí mới nhất. App điện thoại cần xin quyền vị trí, lấy GPS và gửi API; backend không tự thu thập GPS hoặc lưu lịch sử di chuyển.
