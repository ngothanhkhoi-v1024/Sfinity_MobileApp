/** Chunks hướng dẫn app cho RAG (không chứa dữ liệu người dùng). */
export const ASSISTANT_KNOWLEDGE_CHUNKS: { id: string; keywords: string[]; text: string }[] = [
  {
    id: 'check-in',
    keywords: ['check-in', 'check in', 'checkin', 'diem danh'],
    text:
      'Check-in địa điểm: tab Địa điểm → chọn marker trên bản đồ → chi tiết địa điểm → Check-in. Cần bật quyền vị trí để xác nhận bạn ở gần địa điểm.',
  },
  {
    id: 'study-near-me',
    keywords: ['hoc gan toi', 'study near me', 'gan toi', 'near me', 'goi y'],
    text:
      'Học gần tôi: tab Địa điểm hoặc Khám phá → nút Học gần tôi → cho phép GPS → app gợi ý địa điểm và tài liệu trong bán kính ~3km.',
  },
  {
    id: 'upload-doc',
    keywords: ['tai lieu', 'upload', 'dang tai lieu', 'document', 'chia se'],
    text:
      'Chia sẻ tài liệu: tab Tài liệu → nút + trên thanh tiêu đề → điền thông tin và chọn file → xuất bản. Quản lý tại Cá nhân → Bài viết của tôi.',
  },
  {
    id: 'groups',
    keywords: ['nhom', 'group', 'tao nhom', 'chat nhom'],
    text:
      'Nhóm học: tab Cộng đồng → Nhóm → Tạo nhóm → mời thành viên. Trong nhóm có chat, lưu trữ file và bản đồ vị trí thành viên.',
  },
  {
    id: 'friends',
    keywords: ['ban be', 'friend', 'ket ban', 'loi moi'],
    text:
      'Kết bạn: tab Cộng đồng → Bạn bè → tìm người dùng hoặc chấp nhận lời mời.',
  },
  {
    id: 'favorites',
    keywords: ['yeu thich', 'favorite', 'bookmark', 'luu', 'da luu'],
    text:
      'Lưu yêu thích: mở chi tiết tài liệu hoặc địa điểm → nhấn biểu tượng bookmark. Xem lại tại Đã lưu hoặc tab Cá nhân.',
  },
  {
    id: 'password',
    keywords: ['mat khau', 'password', 'doi mat khau', 'change password'],
    text:
      'Đổi mật khẩu: tab Cá nhân → Cài đặt → Đổi mật khẩu. Đăng nhập Google: dùng Thiết lập mật khẩu trong cài đặt.',
  },
  {
    id: 'language',
    keywords: ['ngon ngu', 'language', 'tieng anh', 'english', 'vietnamese'],
    text: 'Đổi ngôn ngữ: tab Cá nhân → Cài đặt → Ngôn ngữ → Tiếng Việt hoặc English.',
  },
  {
    id: 'theme',
    keywords: ['theme', 'giao dien', 'dark', 'sang', 'toi'],
    text: 'Đổi giao diện: tab Cá nhân → Cài đặt → Giao diện → Sáng / Tối / Hệ thống.',
  },
  {
    id: 'feedback',
    keywords: ['phan hoi', 'feedback', 'bao cao', 'report'],
    text:
      'Gửi phản hồi: tab Cá nhân → Phản hồi. Báo cáo vi phạm: mở nội dung → Báo cáo vi phạm.',
  },
  {
    id: 'explore',
    keywords: ['kham pha', 'explore', 'noi bat', 'bang xep hang', 'featured'],
    text:
      'Tab Khám phá: tìm kiếm, nội dung nổi bật, biểu đồ hoạt động tuần, bảng xếp hạng người dùng, nút Học gần tôi.',
  },
  {
    id: 'map',
    keywords: ['ban do', 'map', 'osm', 'chi duong', 'route', 'di duong'],
    text:
      'Tab Địa điểm dùng bản đồ OpenStreetMap. Chi tiết địa điểm có chỉ đường (đi bộ / xe máy) qua OSRM. Có thể hỏi trợ lý thời gian đi nếu bật GPS.',
  },
  {
    id: 'weather',
    keywords: ['thoi tiet', 'weather', 'mua', 'nang', 'nhiet do'],
    text:
      'Thời tiết tại địa điểm lấy từ Open-Meteo (miễn phí). Trợ lý có thể gợi ý học trong nhà hay ngoài trời khi bạn bật vị trí.',
  },
  {
    id: 'assistant',
    keywords: ['hai cau', 'tro ly', 'assistant', 'chatbot', 'ho tro'],
    text:
      'Hải cẩu Sfinity là trợ lý trong app: hướng dẫn tính năng, gợi ý địa điểm/tài liệu công khai, thời tiết và thời gian đi. Không giải bài tập, không đọc chat/tài liệu riêng.',
  },
];
