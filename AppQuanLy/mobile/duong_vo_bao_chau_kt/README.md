# Quản lý điện thoại trẻ em

Ứng dụng Flutter bài lab: đăng nhập, đăng ký, điều hướng theo Role và CRUD thiết bị.

## Chạy ứng dụng

1. Chạy ASP.NET Core Web API, xem cổng HTTP trong Properties/launchSettings.json hoặc Swagger.
2. Sửa BASE_URL trong .env: http://10.0.2.2:5121 cho Android Emulator.
   Điện thoại thật dùng IP LAN của máy chạy API; API phải lắng nghe trên mạng LAN.
3. Chạy flutter pub get rồi flutter run.

Chỉ bản Android debug bật HTTP để thử API nội bộ. Bản release dùng HTTPS hợp lệ.
.env được đóng gói vào ứng dụng, chỉ chứa cấu hình công khai, không chứa bí mật.

## Quy ước API cần khớp với backend

Đã đối chiếu trực tiếp với backend và Swagger trong api_swagger.json.
Đổi đường dẫn trong lib/config/config_url.dart; đổi khóa JSON trong service
và home_screen.dart nếu DTO backend khác.

| Phương thức | Đường dẫn | Dữ liệu |
| --- | --- | --- |
| POST | /api/Authenticate/login | {"username":"parent@example.com","password":"...","otpCode":"123456"} |
| POST | /api/Authenticate/register | {"fullName":"Bảo Châu","password":"...","email":"parent@example.com","role":"Parent"} |
| GET | /api/Device | Trả về mảng Device |
| POST | /api/Device | deviceName, batteryLevel, isLocked, userId |
| PUT | /api/Device/{id} | Các trường như POST và id |
| DELETE | /api/Device/{id} | Không có body; hỗ trợ phản hồi 204 |

Login trả về {"token":"JWT"} hoặc {"accessToken":"JWT"}.
JWT có exp và role, Role, hoặc claim role chuẩn ASP.NET Core.
Admin mở AdminScreen; Staff mở StaffScreen; Parent mở HomeScreen.
Nếu có nhiều role, ưu tiên Admin, Staff, Parent. Role lạ hoặc token hết hạn bị từ chối.
Token lưu SharedPreferences và gắn Authorization: Bearer vào request.
Đăng xuất xóa token; mỗi lần mở ứng dụng bắt đầu từ đăng nhập.
OTP lấy bằng nút Lấy mã OTP sau khi nhập email và mật khẩu.

Device mẫu:

```json
{"id":1,"deviceName":"Samsung A15","batteryLevel":100,"isLocked":false,"userId":"id-trong-jwt"}
```

Backend cần gán tài khoản đăng ký mới quyền Parent, xác thực JWT, kiểm tra quyền
trên API và chỉ cho Parent truy cập thiết bị của chính mình. Giải mã JWT ở Flutter
chỉ phục vụ điều hướng, không thay thế việc kiểm tra chữ ký và quyền trên server.
Admin và Staff hiện có màn hình chào và đăng xuất theo phạm vi bài tập.

## Các file chính

- lib/config/config_url.dart: BASE_URL và endpoint.
- lib/services/api_client.dart: GET, POST, PUT, DELETE; timeout và xử lý lỗi.
- lib/services/auth_service.dart: đăng nhập, đăng ký, role và token.
- lib/screens/login_screen.dart: LoginScreen.
- lib/screens/registration_screen.dart: RegisterScreen.
- lib/screens/admin_screen.dart, staff_screen.dart: màn hình theo quyền.
- lib/screens/home_screen.dart: danh sách Card, thêm/sửa bằng dialog, xác nhận xóa.
- lib/main.dart: nạp .env và khởi chạy.

Kiểm tra: flutter analyze và flutter test.

Hướng dẫn chạy từng bước: [HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md).
