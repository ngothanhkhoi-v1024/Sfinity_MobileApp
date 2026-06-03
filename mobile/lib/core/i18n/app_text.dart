import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('vi'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  final Locale locale;

  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      'appName': 'Sfinity',
      'explore': 'Khám phá',
      'places': 'Địa điểm',
      'documents': 'Tài liệu',
      'viewContent': 'Xem nội dung',
      'publishedPostsList': 'Danh sách bài viết đã xuất bản',
      'profile': 'Cá nhân',
      'search': 'Tìm kiếm',
      'saved': 'Đã lưu',
      'settings': 'Cài đặt',
      'notifications': 'Thông báo',
      'notificationsInApp': 'Thông báo trong ứng dụng',
      'receiveInAppNotifications': 'Nhận thông báo in-app',
      'inAppNotificationSettings': 'Thông báo trong ứng dụng',
      'notificationSettingsDescription': 'Quản lý việc nhận và hiển thị thông báo trong ứng dụng.',
      'notificationsDisabled': 'Đã tắt thông báo',
      'notificationsDisabledDescription': 'Bạn sẽ không thấy danh sách thông báo trong ứng dụng cho đến khi bật lại.',
      'enableNotifications': 'Bật lại thông báo',
      'theme': 'Giao diện',
      'changePassword': 'Đổi mật khẩu',
      'language': 'Ngôn ngữ',
      'system': 'Hệ thống',
      'light': 'Sáng',
      'dark': 'Tối',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'useAppInVietnamese': 'Sử dụng giao diện tiếng Việt',
      'useAppInEnglish': 'Sử dụng giao diện tiếng Anh',
      'editProfile': 'Chỉnh sửa hồ sơ',
      'viewProfile': 'Xem hồ sơ',
      'bio': 'Giới thiệu bản thân',
      'myPosts': 'Tài liệu của tôi',
      'feedback': 'Phản hồi',
      'reportViolation': 'Báo cáo vi phạm',
      'signOut': 'Đăng xuất',
      'shareOnSfinity': 'Chia sẻ trên Sfinity',
      'shareDescription': 'Địa điểm học tập hoặc tài liệu cho cộng đồng',
      'sharePlace': 'Chia sẻ địa điểm',
      'sharePlaceSubtitle': 'Thư viện, quán cà phê, không gian học nhóm…',
      'uploadStudyMaterials': 'Đăng tài liệu học tập',
      'uploadStudyMaterialsSubtitle': 'Ghi chú, slide, đề thi, tóm tắt môn học…',
      'retry': 'Thử lại',
      'searchHint': 'Tìm kiếm...',
      'noNotifications': 'Không có thông báo',
      'markAllRead': 'Đọc tất cả',
      'deleteNotification': 'Xóa thông báo',
      'deleteAllNotifications': 'Xóa tất cả thông báo',
      'deleteAllNotificationsConfirm': 'Bạn có chắc muốn xóa tất cả thông báo?',
      'deleteNotificationConfirm': 'Bạn có chắc muốn xóa thông báo này?',
      'yesDelete': 'Xóa',
      'cancel': 'Hủy',
      'noFavoritesYet': 'Chưa có mục yêu thích',
      'sendFeedback': 'Gửi phản hồi',
      'ratingLabel': 'Đánh giá: {rating} sao',
      'feedbackContent': 'Nội dung phản hồi',
      'submit': 'Gửi',
      'enterAtLeast5Characters': 'Nhập ít nhất 5 ký tự',
      'thanksForYourFeedback': 'Cảm ơn phản hồi của bạn!',
      'reportSubmitted': 'Đã gửi báo cáo',
      'reportViolationTitle': 'Báo cáo vi phạm',
      'type': 'Loại',
      'documentType': 'Tài liệu',
      'userType': 'Người dùng',
      'otherType': 'Khác',
      'targetIdOptional': 'ID đối tượng (tuỳ chọn)',
      'reason': 'Lý do',
      'detailedDescription': 'Mô tả chi tiết',
      'submitReport': 'Gửi báo cáo',
      'login': 'Đăng nhập',
      'welcomeBack': 'Chào mừng bạn quay lại với Sfinity.',
      'email': 'Email',
      'password': 'Mật khẩu',
      'forgotPasswordQuestion': 'Quên mật khẩu?',
      'orContinueWith': 'Hoặc tiếp tục với',
      'continueWithGoogle': 'Đăng nhập với Google',
      'noAccountYetRegister': 'Chưa có tài khoản? Đăng ký',
      'forgotPassword': 'Quên mật khẩu',
      'forgotPasswordDescription': 'Nhập email đã đăng ký để nhận mã OTP khôi phục mật khẩu.',
      'sendOtp': 'Gửi mã OTP',
      'apiError': 'Đã xảy ra lỗi. Vui lòng thử lại.',
      'offlineProfileLoad': 'Mất kết nối mạng, tải thông tin từ SQLite local: {name}',
      'backToSignIn': 'Quay lại đăng nhập',
      'otpVerification': 'Xác thực OTP',
      'otpDescription': 'Nhập mã OTP gồm 6 chữ số đã được gửi tới email của bạn:',
      'otpCode6Digits': 'Mã OTP (6 chữ số)',
      'newPassword': 'Mật khẩu mới',
      'resetPassword': 'Đặt lại mật khẩu',
      'passwordResetSuccessful': 'Đặt lại mật khẩu thành công',
      'registerTitle': 'Tạo tài khoản',
      'register': 'Đăng ký',
      'verifyEmail': 'Xác thực Email',
      'registerSuccess': 'Đăng ký tài khoản thành công!',
      'understood': 'Đã hiểu & Đăng nhập',
      'welcomeTitle': 'Chào mừng Sfinity',
      'welcomeSubtitle': 'Khám phá nội dung và quản lý yêu thích của bạn.',
      'smartSearchTitle': 'Tìm kiếm thông minh',
      'smartSearchSubtitle': 'Lọc, sắp xếp và tìm nội dung nhanh chóng.',
      'stayConnectedTitle': 'Kết nối mọi lúc',
      'stayConnectedSubtitle': 'Đăng nhập để đồng bộ dữ liệu trên mọi thiết bị.',
      'next': 'Tiếp theo',
      'getStarted': 'Bắt đầu',
      'emailVerified': 'Email đã xác thực',
      'signIn': 'Đăng nhập',
      'welcomeTitleShort': 'Chào mừng Sfinity',
      'welcomeDescShort': 'Khám phá nội dung và quản lý yêu thích của bạn.',
      'studyPlacesOrMaterials': 'Địa điểm học tập hoặc tài liệu cho cộng đồng',
      'libraryCafeStudyGroupSpace': 'Thư viện, quán cà phê, không gian học nhóm…',
      'notesSlidesExamPapersSubjectSummaries': 'Ghi chú, slide, đề thi, tóm tắt môn học…',
      'createGroupTitle': 'Tạo nhóm mới',
      'editGroupTitle': 'Chỉnh sửa thông tin nhóm',
      'groupNameLabel': 'Tên nhóm *',
      'groupNameHint': 'Nhập tên nhóm của bạn',
      'groupDescLabel': 'Mô tả (tùy chọn)',
      'groupDescHint': 'Thêm vài lời về nhóm này...',
      'publicGroupLabel': 'Nhóm công khai',
      'publicGroupHint': 'Bất kỳ ai cũng có thể tìm và gia nhập nhóm này.',
      'privateGroupHint': 'Chỉ những thành viên được mời mới có thể tham gia.',
      'autoApproveLabel': 'Tự động duyệt thành viên',
      'autoApproveHint': 'Thành viên mới tham gia trực tiếp không cần phê duyệt.',
      'requireApprovalHint': 'Thành viên mới cần được chủ nhóm phê duyệt trước.',
      'createGroupBtn': 'Tạo nhóm',
      'saveChangesBtn': 'Lưu thay đổi',
      'cancelBtn': 'Hủy',
      'joinRequestsLabel': 'Yêu cầu duyệt',
      'approveBtn': 'Duyệt',
      'declineBtn': 'Từ chối',
      'welcomeDescription': 'Khám phá hàng nghìn địa điểm học tập và tài liệu được cộng đồng chia sẻ. Lưu lại những gì yêu thích và truy cập mọi lúc.',
      'smartSearchDescription': 'Bộ lọc thông minh giúp bạn tìm đúng nội dung trong vài giây. Sắp xếp theo chủ đề, khoảng cách hoặc mức độ phù hợp.',
      'stayConnectedDescription': 'Đăng nhập một lần, dữ liệu tự động đồng bộ trên tất cả thiết bị. Không bao giờ mất đi nội dung yêu thích dù đổi điện thoại.',
      'welcomeBadge': 'Nền tảng học tập',
      'smartSearchBadge': 'Nhanh & chính xác',
      'stayConnectedBadge': 'Đa thiết bị',
      'skip': 'Bỏ qua',
      'getStartedNow': 'Bắt đầu ngay',
      'invitesTab': 'Lời mời',
      'placeDetail': 'Chi tiết địa điểm',
      'placeUpdated': 'Cập nhật địa điểm',
      'memberRemoved': 'Đã xóa thành viên',
      'gender': 'Giới tính',
      'dateOfBirth': 'Ngày sinh',
      'selectDateOfBirth': 'Chọn ngày sinh',
      'personal': 'Cá nhân',
      'community': 'Cộng đồng',
      'documentUploadTitle': 'Đăng tải tài liệu',
      'editDocument': 'Chỉnh sửa tài liệu',
      'shareToGroup': 'Chia sẻ đến nhóm',
      'loadDocumentFor': 'Tải tài liệu cho {name}',
      'documentName': 'Tên tài liệu',
      'documentNameHint': 'Nhập tên tài liệu',
      'studyDocument': 'Tài liệu học tập',
      'category': 'Danh mục',
      'selectCategory': 'Chọn danh mục',
      'publicAllSee': 'Công khai - Mọi người đều thấy',
      'reset_': 'Đặt lại',
      'tags': 'Thẻ',
      'postDocument': 'Đăng tài liệu',
      'documentUpdateSuccess': 'Cập nhật tài liệu thành công',
      'documentShareSuccess': 'Chia sẻ tài liệu thành công',
      'documentStudyShared': 'Tài liệu học tập được chia sẻ',
      'pdfDocument': 'Tài liệu PDF',
      'tapSelectPDF': 'Nhấn để chọn PDF',
      'changePdf': 'Đổi PDF',
      'uploadDocument': 'Tải lên tài liệu',
      'studyMaterials': 'Tài liệu học tập',
      'documentLabel': 'Tài liệu',
      'untitledDocument': 'Tài liệu không tiêu đề',
      'shareDocument': 'Chia sẻ tài liệu',
      'allFiles': 'Tất cả tệp',
      'images': 'Hình ảnh',
      'files': 'Tệp',
      'fileName': 'Tên tệp',
      'documentDetail': 'Chi tiết tài liệu',
      'uploadedDocuments': 'Tài liệu đã tải lên',
      'placeName': 'Tên địa điểm',
      'placeNameRequired': 'Tên địa điểm là bắt buộc',
      'placeDescription': 'Mô tả địa điểm',
      'additionalDescription': 'Mô tả bổ sung',
      'placeDescriptionHint': 'Mô tả ngắn gọn về địa điểm này...',
      'placeDescriptionDetail': 'Chi tiết về địa điểm',
      'placeDescriptionMin': 'Mô tả cần ít nhất 10 ký tự',
      'placeWillShowMap': 'Địa điểm sẽ hiển thị trên bản đồ',
      'placeDisplayOnMap': 'Hiển thị địa điểm trên bản đồ',
      'saveThisPlace': 'Lưu địa điểm này',
      'favoritePlace': 'Yêu thích địa điểm',
      'unfavoritePlace': 'Bỏ yêu thích địa điểm',
      'favoritePlaceCommunity': 'Yêu thích địa điểm',
      'unfavoritePlaceCommunity': 'Bỏ yêu thích',
      'savedPlace': 'Địa điểm đã lưu',
      'loginToSavePlace': 'Đăng nhập để lưu địa điểm',
      'documentsAtPlace': 'Tài liệu tại địa điểm',
      'noDocuments': 'Không có tài liệu',
      'noDocumentsPlace': 'Không có tài liệu tại địa điểm này',
      'loginToCheckin': 'Đăng nhập để check-in',
      'loginToCheckinDesc': 'Vui lòng đăng nhập để check-in tại địa điểm',
      'updateGPS': 'Cập nhật GPS',
      'enableGPSCheckin': 'Bật GPS để check-in',
      'enableGPSDistance': 'Bật GPS để đo khoảng cách',
      'enableGPSNearMe': 'Bật GPS để tìm gần đây',
      'yourLocation': 'Vị trí của bạn',
      'noYourLocation': 'Không có vị trí của bạn',
      'cannotGetGPS': 'Không thể lấy vị trí GPS',
      'cannotGetGPSCheckin': 'Không thể check-in - GPS không khả dụng',
      'cannotGetGPSDirections': 'Không thể lấy chỉ đường - GPS không khả dụng',
      'cannotGetCurrentLocation': 'Không thể lấy vị trí hiện tại',
      'cannotLoadDirections': 'Không thể tải chỉ đường',
      'noPathFound': 'Không tìm thấy đường đi',
      'noSuitableRoute': 'Không có tuyến đường phù hợp',
      'start': 'Bắt đầu',
      'continueStraight': 'Tiếp tục đi thẳng',
      'continue_': 'Tiếp tục',
      'noLocationYet': 'Chưa có vị trí',
      'cannotCreatePlace': 'Không thể tạo địa điểm',
      'cannotUpdatePlace': 'Không thể cập nhật địa điểm',
      'invalidCoordinates': 'Tọa độ không hợp lệ',
      'allZones': 'Tất cả khu vực',
      'filterAmenities': 'Lọc tiện nghi',
      'holdMapOrButton': 'Giữ bản đồ hoặc nhấn nút',
      'holdMapOrPressPlus': 'Giữ bản đồ hoặc nhấn dấu cộng',
      'selectedLocation': 'Vị trí đã chọn',
      'myPlaces': 'Địa điểm của tôi',
      'communityPlaces': 'Địa điểm cộng đồng',
      'saveNewPlace': 'Lưu địa điểm mới',
      'savePlace': 'Lưu địa điểm',
      'updatePlace': 'Cập nhật địa điểm',
      'editPlace': 'Sửa địa điểm',
      'deletePlace': 'Xóa địa điểm',
      'deletePlaceConfirm': 'Xác nhận xóa địa điểm?',
      'deletePlaceDesc': 'Hành động này không thể hoàn tác.',
      'placeDeleted': 'Đã xóa địa điểm',
      'placeNotFound': 'Không tìm thấy địa điểm',
      'viewOnMap': 'Xem trên bản đồ',
      'viewPlaceDetail': 'Xem chi tiết địa điểm',
      'managePlace': 'Quản lý địa điểm',
      'noPlace': 'Không có địa điểm',
      'noPlaceCommunity': 'Không có địa điểm cộng đồng',
      'noPlaceYet': 'Chưa có địa điểm',
      'noPlaceFilter': 'Không có địa điểm phù hợp',
      'addFirstPlace': 'Thêm địa điểm đầu tiên',
      'noPlaceFound': 'Không tìm thấy địa điểm',
      'groupCreated': 'Đã tạo nhóm',
      'groupNotFound': 'Không tìm thấy nhóm',
      'addMembers': 'Thêm thành viên',
      'leaveGroup': 'Rời nhóm',
      'leaveGroup2': 'Bạn có chắc muốn rời nhóm này?',
      'leaveGroupConfirm': 'Xác nhận rời nhóm',
      'leaveGroupBtn': 'Rời nhóm',
      'disband': 'Giải tán',
      'disbandGroup': 'Giải tán nhóm',
      'disbandGroupConfirm': 'Bạn có chắc muốn giải tán nhóm này?',
      'confirmDisbandGroup': 'Hành động này không thể hoàn tác.',
      'confirm': 'Xác nhận',
      'selectNewOwnerTitle': 'Chọn chủ nhóm mới',
      'mustTransferOwnership': 'Bạn phải chuyển quyền sở hữu trước khi rời nhóm',
      'memberNotFound': 'Không tìm thấy thành viên',
      'searchMembers': 'Tìm thành viên',
      'publicGroup': 'Nhóm công khai',
      'privateGroup': 'Nhóm riêng tư',
      'groupOptions': 'Tùy chọn nhóm',
      'groupChatTab': 'Trò chuyện',
      'groupStorageTab': 'Lưu trữ',
      'groupMembersTab': 'Thành viên',
      'deleteMemberConfirm': 'Xóa thành viên khỏi nhóm?',
      'cannotRemoveMember': 'Không thể xóa thành viên',
      'inviteToGroup': 'Mời vào nhóm',
      'groupMembers': 'Thành viên nhóm',
      'studyGroups': 'Nhóm học tập',
      'myGroups': 'Nhóm của tôi',
      'exploreGroups': 'Khám phá nhóm',
      'friends': 'Bạn bè',
      'createGroup': 'Tạo nhóm',
      'inviteReceived': 'Lời mời đã nhận',
      'groupStudy': 'Nhóm học tập',
      'someone': 'Ai đó',
      'invitedYou': 'đã mời bạn',
      'declineInviteSuccess': 'Đã từ chối lời mời',
      'declineInviteFailed': 'Từ chối lời mời thất bại',
      'acceptInviteSuccess': 'Đã chấp nhận lời mời',
      'acceptInviteFailed': 'Chấp nhận lời mời thất bại',
      'joinGroupSuccess': 'Đã gia nhập nhóm',
      'joinGroupPending': 'Đang chờ duyệt',
      'cancelRequestSuccess': 'Đã hủy yêu cầu',
      'noGroupsYet2': 'Chưa có nhóm nào',
      'noGroupsNewExplore': 'Khám phá để tìm nhóm mới',
      'noGroupsMatch': 'Không có nhóm phù hợp',
      'searchPublicGroups': 'Tìm nhóm công khai',
      'errorOccurred': 'Đã xảy ra lỗi',
      'groupChat': 'Trò chuyện nhóm',
      'decline': 'Từ chối',
      'accept': 'Chấp nhận',
      'noInvites': 'Không có lời mời',
      'friendRequests': 'Yêu cầu kết bạn',
      'sentRequests': 'Đã gửi yêu cầu',
      'friendsTab': 'Bạn bè',
      'discoverTab': 'Khám phá',
      'cannotOpenPDF': 'Không thể mở PDF',
      'cannotConnectServer': 'Không thể kết nối máy chủ',
      'favoriteDocument': 'Yêu thích tài liệu',
      'unfavoriteDocument': 'Bỏ yêu thích tài liệu',
      'noDownloadLink': 'Không có liên kết tải xuống',
      'openDocumentSuccess': 'Đã mở tài liệu',
      'cannotOpenDocument': 'Không thể mở tài liệu',
      'rateDocumentSuccess': 'Đã đánh giá tài liệu',
      'rateDocumentFailed': 'Đánh giá tài liệu thất bại',
      'ratingDeleted': 'Đã xóa đánh giá',
      'cannotDeleteRating': 'Không thể xóa đánh giá',
      'noRating': 'Chưa có đánh giá',
      'loading': 'Đang tải...',
      'noResourceFound': 'Không tìm thấy tài nguyên',
      'relatedTags': 'Thẻ liên quan',
      'ratingAndComments': 'Đánh giá và bình luận',
      'yourRating': 'Đánh giá của bạn',
      'sendRating': 'Gửi đánh giá',
      'ratingHint': 'Chia sẻ trải nghiệm của bạn...',
      'noComments': 'Chưa có bình luận',
      'all': 'Tất cả',
      'newest': 'Mới nhất',
      'noCommentsFound': 'Không tìm thấy bình luận',
      'loadMoreComments': 'Tải thêm bình luận',
      'download': 'Tải xuống',
      'share': 'Chia sẻ',
      'communityContent': 'Nội dung cộng đồng',
      'searchGroupHint': 'Tìm nhóm...',
      'noGroupsExplore': 'Khám phá để tìm nhóm mới',
      'noGroupsFound': 'Không tìm thấy nhóm',
      'cancelRequest': 'Hủy yêu cầu',
      'noFriendsSearchHint': 'Tìm bạn bè...',
      'noUserFound': 'Không tìm thấy người dùng',
      'searchByNameEmail': 'Tìm theo tên hoặc email',
      'friendRequestSent': 'Đã gửi yêu cầu kết bạn',
      'friendRequestError': 'Gửi yêu cầu kết bạn thất bại',
      'delete': 'Xóa',
      'remove': 'Xóa',
      'success': 'Thành công',
      'error': 'Lỗi',
      'groupChatError': 'Lỗi trò chuyện nhóm',
      'sendImageFailed': 'Gửi hình ảnh thất bại',
      'sendFileFailed': 'Gửi tệp thất bại',
      'loadPlaceListError': 'Lỗi tải danh sách địa điểm',
      'mapDirections': 'Chỉ đường trên bản đồ',
      'tapToViewMap': 'Nhấn để xem bản đồ',
      'fileSizeLimit': 'Kích thước tệp giới hạn: 10MB',
      'searchDocument': 'Tìm tài liệu',
      'searchDocumentHint': 'Tìm tài liệu...',
      'documentSheet': 'Tài liệu',
      'noDocumentsFound': 'Không tìm thấy tài liệu',
      'loadDocumentListFailed': 'Tải danh sách tài liệu thất bại',
      'noPlaceFoundInArea': 'Không tìm thấy địa điểm trong khu vực',
      'findAgain': 'Tìm lại',
      'result': 'Kết quả',
      'anonymous': 'Ẩn danh',
      'uploadFailed': 'Tải lên thất bại',
      'searchPlaceByName': 'Tìm địa điểm theo tên',
      'searchFriends': 'Tìm bạn bè',
      'searchPlace': 'Tìm địa điểm',
      'searchGroup': 'Tìm nhóm',
      'searchUser': 'Tìm người dùng',
      'searchFileByName': 'Tìm tệp theo tên',
      'searchResults': 'Kết quả tìm kiếm',
      'noResultsFound': 'Không tìm thấy kết quả',
      'clearSearch': 'Xóa tìm kiếm',
      'close': 'Đóng',
      'exploreTopPanel': 'Khám phá',
      'studyNearMe': 'Học gần tôi',
      'pleaseLogin': 'Vui lòng đăng nhập',
      // Missing validators
      'enterValidEmail': 'Nhập email hợp lệ',
      'passwordMinChars': 'Mật khẩu tối thiểu 6 ký tự',
      'passwordRequirements': 'Mật khẩu phải chứa chữ hoa, thường, số và ký tự đặc biệt',
      'enterValidName': 'Nhập họ tên (tối thiểu 2 ký tự)',
      'enterConfirmPassword': 'Nhập lại mật khẩu để xác nhận',
      'passwordConfirmMismatch': 'Mật khẩu xác nhận không khớp',
      'otp6Chars': 'Mã OTP phải gồm 6 chữ số',
      'fullName': 'Họ tên',
      'confirmPasswordField': 'Xác nhận mật khẩu',
      'alreadyHaveAccount': 'Đã có tài khoản? Đăng nhập',
      // Missing document
      'yourUploadedDocuments': 'Tài liệu đã tải lên',
      'documentsCategory': 'Danh mục tài liệu',
      'noSearchResults': 'Không tìm thấy kết quả cho "{query}"',
      'cancelBtn2': 'Hủy bỏ',
      // Missing friendships
      'addFriends': 'Thêm bạn bè',
      'requestSent': 'Đã gửi yêu cầu',
      'noFriends': 'Chưa có bạn bè',
      'noFriendsFound': 'Không tìm thấy bạn bè',
      'unfriend': 'Hủy kết bạn',
      'friendRequestSuccess': 'Đã gửi yêu cầu kết bạn',
      'friend': 'Bạn bè',
      'declineInvite': 'Từ chối lời mời',
      // Missing groups
      'studyGroup': 'Nhóm học tập',
      'noMessages': 'Không có tin nhắn',
      'beFirstToSend': 'Hãy gửi tin nhắn đầu tiên',
      'attach': 'Đính kèm',
      'photoLibrary': 'Thư viện ảnh',
      'camera': 'Máy ảnh',
      'selectFile': 'Chọn tệp',
      'shareLocation': 'Chia sẻ vị trí',
      'uploadingProgress': 'Đang tải lên{fileName}',
      'reactToMessage': 'Phản hồi tin nhắn',
      'deleteMessage': 'Xóa tin nhắn',
      'messageWillDeleteAll': 'Thao tác này sẽ xóa tin nhắn vĩnh viễn.',
      'deleteMessageConfirm': 'Xóa tin nhắn?',
      'deleteMessageConfirmDesc': 'Bạn không thể khôi phục tin nhắn này sau khi xóa.',
      'messageDeleted': 'Tin nhắn đã bị xóa',
      'seen': 'Đã xem',
      'youShared': 'Bạn đã chia sẻ',
      'sharedDocument': '{name} đã chia sẻ',
      'fileUploadedSuccess': 'Đã tải tệp lên: {fileName}',
      'fileUploadFailed': 'Tải tệp thất bại: {error}',
      'sharedFile': 'Tệp đã chia sẻ',
      'locationPlaceholder': 'Vị trí',
      'locationShared': 'Địa điểm đã chia sẻ',
      'members': 'thành viên',
      'groupsTab': 'Nhóm',
      'publicBadge': 'Công khai',
      'member': 'thành viên',
      'groupOwner': 'Chủ nhóm',
      'adminBadge': 'Quản trị viên',
      'noMessagesGroup': 'Không có tin nhắn trong nhóm',
      'noGroupsYet': 'Chưa có nhóm nào',
      'createGroupHint': 'Tạo nhóm mới để bắt đầu học tập cùng bạn bè',
      'location': 'Vị trí',
      'groupStorage': 'Kho lưu trữ ({count})',
      'allMembers': 'Tất cả thành viên',
      'tryDifferentKeyword': 'Thử từ khóa khác',
      'shareResources': 'Chia sẻ tài liệu cho nhóm',
      'imageSharedBy': '{name} đã chia sẻ ảnh',
      'placeSharedSentBy': 'Do {name} gửi',
      'suggestedFriends': 'Gợi ý bạn bè',
      'noUsersFound': 'Không tìm thấy người dùng',
      'noFriendsList': 'Không có bạn bè trong danh sách',
      'pending': 'Đang chờ',
      'sendInviteSuccess': 'Đã gửi lời mời đến {name}',
      'sendInviteFailed': 'Gửi lời mời thất bại',
      'invite': 'Mời',
      // Missing places
      'noAddress': 'Chưa có địa chỉ',
      'searchPlaceSheet': 'Tìm kiếm địa điểm',
      'publicPlaces': 'Địa điểm công khai',
      'selectFromList': 'Chọn từ danh sách',
      'manualInput': 'Nhập thủ công',
      'documentId': 'ID tài liệu',
      'shareAndToGroup': 'Chia sẻ đến nhóm',
      'results': 'Kết quả',
      'acceptInvite': 'Chấp nhận lời mời',
      'addPhotos': 'Thêm ảnh',
      'noPhotos': 'Chưa có ảnh',
      'loadDocForPlace': 'Tải tài liệu cho địa điểm',
      'account': 'Tài khoản',
      'address': 'Địa chỉ',
      'nearby': 'Gần đây',
      'pleaseTryAgain': 'Vui lòng thử lại',
      'removeFilter': 'Xóa bộ lọc',
      'map': 'Bản đồ',
      'list': 'Danh sách',
      'filter': 'Lọc',
      // Missing profile
      'profileUpdatedSuccess': 'Cập nhật hồ sơ thành công',
      'selectPhoto': 'Chọn ảnh',
      'male': 'Nam',
      'female': 'Nữ',
      'other': 'Khác',
      'save': 'Lưu',
      // Missing security
      'changePasswordSuccess': 'Đổi mật khẩu thành công',
      'currentPassword': 'Mật khẩu hiện tại',
      'newPasswordRequired': 'Mật khẩu mới',
    },
    'en': {
      'appName': 'Sfinity',
      'explore': 'Explore',
      'places': 'Places',
      'documents': 'Documents',
      'viewContent': 'View content',
      'publishedPostsList': 'List of published posts',
      'profile': 'Profile',
      'search': 'Search',
      'saved': 'Saved',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'notificationsInApp': 'In-app notifications',
      'receiveInAppNotifications': 'Receive in-app notifications',
      'inAppNotificationSettings': 'In-app notifications',
      'notificationSettingsDescription': 'Manage how in-app notifications are received and displayed.',
      'notificationsDisabled': 'Notifications turned off',
      'notificationsDisabledDescription': 'You will not see the in-app notification list until you turn it back on.',
      'enableNotifications': 'Enable notifications',
      'theme': 'Theme',
      'changePassword': 'Change password',
      'language': 'Language',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'useAppInVietnamese': 'Use the app in Vietnamese',
      'useAppInEnglish': 'Use the app in English',
      'editProfile': 'Edit profile',
      'viewProfile': 'View profile',
      'bio': 'About me',
      'myPosts': 'My documents',
      'feedback': 'Feedback',
      'reportViolation': 'Report violation',
      'signOut': 'Sign out',
      'shareOnSfinity': 'Share on Sfinity',
      'shareDescription': 'Study places or materials for the community',
      'sharePlace': 'Share a place',
      'sharePlaceSubtitle': 'Library, café, study group space…',
      'uploadStudyMaterials': 'Upload study materials',
      'uploadStudyMaterialsSubtitle': 'Notes, slides, exam papers, subject summaries…',
      'retry': 'Retry',
      'searchHint': 'Search...',
      'noNotifications': 'No notifications',
      'markAllRead': 'Mark all read',
      'deleteNotification': 'Delete notification',
      'deleteAllNotifications': 'Delete all notifications',
      'deleteAllNotificationsConfirm': 'Are you sure you want to delete all notifications?',
      'deleteNotificationConfirm': 'Are you sure you want to delete this notification?',
      'yesDelete': 'Delete',
      'cancel': 'Cancel',
      'noFavoritesYet': 'No favorites yet',
      'sendFeedback': 'Send feedback',
      'ratingLabel': 'Rating: {rating} stars',
      'feedbackContent': 'Feedback content',
      'submit': 'Submit',
      'enterAtLeast5Characters': 'Enter at least 5 characters',
      'thanksForYourFeedback': 'Thanks for your feedback!',
      'reportSubmitted': 'Report submitted',
      'reportViolationTitle': 'Report violation',
      'type': 'Type',
      'documentType': 'Document',
      'userType': 'User',
      'otherType': 'Other',
      'targetIdOptional': 'Target ID (optional)',
      'reason': 'Reason',
      'detailedDescription': 'Detailed description',
      'submitReport': 'Submit report',
      'login': 'Sign in',
      'welcomeBack': 'Welcome back to Sfinity.',
      'email': 'Email',
      'password': 'Password',
      'forgotPasswordQuestion': 'Forgot password?',
      'orContinueWith': 'Or continue with',
      'continueWithGoogle': 'Continue with Google',
      'noAccountYetRegister': 'No account yet? Register',
      'forgotPassword': 'Forgot password',
      'forgotPasswordDescription': 'Enter your registered email to receive a password reset OTP.',
      'sendOtp': 'Send OTP',
      'apiError': 'An error occurred. Please try again.',
      'offlineProfileLoad': 'No network connection, loading profile from local SQLite: {name}',
      'backToSignIn': 'Back to sign in',
      'otpVerification': 'OTP verification',
      'otpDescription': 'Enter the 6-digit OTP sent to your email:',
      'otpCode6Digits': 'OTP code (6 digits)',
      'newPassword': 'New password',
      'resetPassword': 'Reset password',
      'passwordResetSuccessful': 'Password reset successful',
      'welcomeTitle': 'Welcome to Sfinity',
      'welcomeSubtitle': 'Discover content and manage your favorites.',
      'smartSearchTitle': 'Smart search',
      'smartSearchSubtitle': 'Filter, sort, and find content quickly.',
      'stayConnectedTitle': 'Stay connected',
      'stayConnectedSubtitle': 'Sign in to sync your data across devices.',
      'next': 'Next',
      'getStarted': 'Get started',
      'emailVerified': 'Email verified',
      'signIn': 'Sign in',
      'welcomeTitleShort': 'Welcome to Sfinity',
      'welcomeDescShort': 'Discover content and manage your favorites.',
      'studyPlacesOrMaterials': 'Study places or materials for the community',
      'libraryCafeStudyGroupSpace': 'Library, café, study group space…',
      'notesSlidesExamPapersSubjectSummaries': 'Notes, slides, exam papers, subject summaries…',
      'createGroupTitle': 'Create new group',
      'editGroupTitle': 'Edit group details',
      'groupNameLabel': 'Group name *',
      'groupNameHint': 'Enter your group name',
      'groupDescLabel': 'Description (optional)',
      'groupDescHint': 'Add a few words about this group...',
      'publicGroupLabel': 'Public group',
      'publicGroupHint': 'Anyone can find and join this group.',
      'privateGroupHint': 'Only invited members can join.',
      'autoApproveLabel': 'Auto-approve members',
      'autoApproveHint': 'New members join directly without approval.',
      'requireApprovalHint': 'New members need owner approval first.',
      'createGroupBtn': 'Create group',
      'saveChangesBtn': 'Save changes',
      'cancelBtn': 'Cancel',
      'joinRequestsLabel': 'Join requests',
      'approveBtn': 'Approve',
      'declineBtn': 'Decline',
      'welcomeDescription': 'Discover thousands of study spots and community-shared materials. Save your favorites and access them anytime.',
      'smartSearchDescription': 'Smart filters help you find the right content in seconds. Sort by topic, distance, or relevance.',
      'stayConnectedDescription': 'Sign in once and your data syncs automatically across all devices. Never lose your favorites when switching phones.',
      'welcomeBadge': 'Learning platform',
      'smartSearchBadge': 'Fast & accurate',
      'stayConnectedBadge': 'Multi-device',
      'skip': 'Skip',
      'getStartedNow': 'Get started',
      'invitesTab': 'Invitations',
      'placeDetail': 'Place detail',
      'placeUpdated': 'Place updated',
      'memberRemoved': 'Removed member',
      'registerTitle': 'Create account',
      'registerSuccess': 'Registration successful',
      'register': 'Register',
      'verifyEmail': 'Verify email',
      'understood': 'Understood',
      'gender': 'Gender',
      'dateOfBirth': 'Date of birth',
      'selectDateOfBirth': 'Select date of birth',
      'personal': 'Personal',
      'community': 'Community',
      'documentUploadTitle': 'Upload document',
      'editDocument': 'Edit document',
      'shareToGroup': 'Share to group',
      'loadDocumentFor': 'Load document for {name}',
      'documentName': 'Document name',
      'documentNameHint': 'Enter document name',
      'studyDocument': 'Study document',
      'category': 'Category',
      'selectCategory': 'Select category',
      'publicAllSee': 'Public - Everyone can see',
      'reset_': 'Reset',
      'tags': 'Tags',
      'postDocument': 'Post document',
      'documentUpdateSuccess': 'Document updated successfully',
      'documentShareSuccess': 'Document shared successfully',
      'documentStudyShared': 'Study document shared',
      'pdfDocument': 'PDF document',
      'tapSelectPDF': 'Tap to select PDF',
      'changePdf': 'Change PDF',
      'uploadDocument': 'Upload document',
      'studyMaterials': 'Study materials',
      'documentLabel': 'Document',
      'untitledDocument': 'Untitled document',
      'shareDocument': 'Share document',
      'allFiles': 'All files',
      'images': 'Images',
      'files': 'Files',
      'fileName': 'File name',
      'documentDetail': 'Document detail',
      'uploadedDocuments': 'Uploaded documents',
      'placeName': 'Place name',
      'placeNameRequired': 'Place name is required',
      'placeDescription': 'Place description',
      'additionalDescription': 'Additional description',
      'placeDescriptionHint': 'Brief description of this place...',
      'placeDescriptionDetail': 'Place details',
      'placeDescriptionMin': 'Description must be at least 10 characters',
      'placeWillShowMap': 'Place will be shown on the map',
      'placeDisplayOnMap': 'Display place on map',
      'saveThisPlace': 'Save this place',
      'favoritePlace': 'Favorite place',
      'unfavoritePlace': 'Unfavorite place',
      'favoritePlaceCommunity': 'Favorite place',
      'unfavoritePlaceCommunity': 'Unfavorite',
      'savedPlace': 'Saved place',
      'loginToSavePlace': 'Sign in to save place',
      'documentsAtPlace': 'Documents at this place',
      'noDocuments': 'No documents',
      'noDocumentsPlace': 'No documents at this place',
      'loginToCheckin': 'Sign in to check in',
      'loginToCheckinDesc': 'Please sign in to check in at this place',
      'updateGPS': 'Update GPS',
      'enableGPSCheckin': 'Enable GPS to check in',
      'enableGPSDistance': 'Enable GPS for distance',
      'enableGPSNearMe': 'Enable GPS for near me',
      'yourLocation': 'Your location',
      'noYourLocation': 'No your location',
      'cannotGetGPS': 'Cannot get GPS location',
      'cannotGetGPSCheckin': 'Cannot check in - GPS not available',
      'cannotGetGPSDirections': 'Cannot get directions - GPS not available',
      'cannotGetCurrentLocation': 'Cannot get current location',
      'cannotLoadDirections': 'Cannot load directions',
      'noPathFound': 'No path found',
      'noSuitableRoute': 'No suitable route',
      'start': 'Start',
      'continueStraight': 'Continue straight',
      'continue_': 'Continue',
      'noLocationYet': 'No location yet',
      'cannotCreatePlace': 'Cannot create place',
      'cannotUpdatePlace': 'Cannot update place',
      'invalidCoordinates': 'Invalid coordinates',
      'allZones': 'All zones',
      'filterAmenities': 'Filter amenities',
      'holdMapOrButton': 'Hold map or press button',
      'holdMapOrPressPlus': 'Hold map or press plus',
      'selectedLocation': 'Selected location',
      'myPlaces': 'My places',
      'communityPlaces': 'Community places',
      'saveNewPlace': 'Save new place',
      'savePlace': 'Save place',
      'updatePlace': 'Update place',
      'editPlace': 'Edit place',
      'deletePlaceConfirm': 'Confirm delete place?',
      'deletePlaceDesc': 'This action cannot be undone.',
      'placeDeleted': 'Place deleted',
      'placeNotFound': 'Place not found',
      'viewOnMap': 'View on map',
      'viewPlaceDetail': 'View place detail',
      'managePlace': 'Manage place',
      'noPlace': 'No places',
      'noPlaceCommunity': 'No community places',
      'noPlaceYet': 'No places yet',
      'noPlaceFilter': 'No places match filter',
      'addFirstPlace': 'Add your first place',
      'noPlaceFound': 'No place found',
      'groupCreated': 'Group created',
      'groupNotFound': 'Group not found',
      'addMembers': 'Add members',
      'leaveGroup': 'Leave group',
      'leaveGroup2': 'Are you sure you want to leave this group?',
      'leaveGroupConfirm': 'Confirm leaving group',
      'leaveGroupBtn': 'Leave group',
      'disband': 'Disband',
      'disbandGroup': 'Disband group',
      'disbandGroupConfirm': 'Are you sure you want to disband this group?',
      'confirmDisbandGroup': 'This action cannot be undone.',
      'confirm': 'Confirm',
      'selectNewOwnerTitle': 'Select new owner',
      'mustTransferOwnership': 'You must transfer ownership before leaving',
      'memberNotFound': 'Member not found',
      'searchMembers': 'Search members',
      'publicGroup': 'Public group',
      'privateGroup': 'Private group',
      'groupOptions': 'Group options',
      'groupChatTab': 'Chat',
      'groupStorageTab': 'Storage',
      'groupMembersTab': 'Members',
      'deleteMemberConfirm': 'Remove member from group?',
      'cannotRemoveMember': 'Cannot remove member',
      'inviteToGroup': 'Invite to group',
      'groupMembers': 'Group members',
      'studyGroups': 'Study groups',
      'myGroups': 'My groups',
      'exploreGroups': 'Explore groups',
      'friends': 'Friends',
      'createGroup': 'Create group',
      'inviteReceived': 'Invite received',
      'groupStudy': 'Study group',
      'someone': 'Someone',
      'invitedYou': 'has invited you',
      'declineInviteSuccess': 'Invite declined',
      'declineInviteFailed': 'Failed to decline invite',
      'acceptInviteSuccess': 'Invite accepted',
      'acceptInviteFailed': 'Failed to accept invite',
      'joinGroupSuccess': 'Joined group',
      'joinGroupPending': 'Pending approval',
      'cancelRequestSuccess': 'Request cancelled',
      'noGroupsYet2': 'No groups yet',
      'noGroupsNewExplore': 'Explore to find new groups',
      'noGroupsMatch': 'No matching groups',
      'searchPublicGroups': 'Search public groups',
      'errorOccurred': 'An error occurred',
      'groupChat': 'Group chat',
      'decline': 'Decline',
      'accept': 'Accept',
      'noInvites': 'No invites',
      'friendRequests': 'Friend requests',
      'sentRequests': 'Sent requests',
      'friendsTab': 'Friends',
      'discoverTab': 'Discover',
      'cannotOpenPDF': 'Cannot open PDF',
      'cannotConnectServer': 'Cannot connect to server',
      'favoriteDocument': 'Favorite document',
      'unfavoriteDocument': 'Unfavorite document',
      'noDownloadLink': 'No download link',
      'openDocumentSuccess': 'Document opened',
      'cannotOpenDocument': 'Cannot open document',
      'rateDocumentSuccess': 'Document rated',
      'rateDocumentFailed': 'Failed to rate document',
      'ratingDeleted': 'Rating deleted',
      'cannotDeleteRating': 'Cannot delete rating',
      'noRating': 'No rating',
      'loading': 'Loading...',
      'noResourceFound': 'No resource found',
      'relatedTags': 'Related tags',
      'ratingAndComments': 'Rating and comments',
      'yourRating': 'Your rating',
      'sendRating': 'Send rating',
      'ratingHint': 'Share your experience...',
      'noComments': 'No comments',
      'all': 'All',
      'newest': 'Newest',
      'noCommentsFound': 'No comments found',
      'loadMoreComments': 'Load more comments',
      'download': 'Download',
      'share': 'Share',
      'communityContent': 'Community content',
      'searchGroupHint': 'Search groups...',
      'noGroupsExplore': 'Explore to find new groups',
      'noGroupsFound': 'No groups found',
      'searchUserByNameEmail': 'Search users by name or email',
      'cancelRequest': 'Cancel request',
      'noFriendsSearchHint': 'Search friends...',
      'noUserFound': 'No user found',
      'searchByNameEmail': 'Search by name or email',
      'friendRequestSent': 'Friend request sent',
      'friendRequestError': 'Failed to send friend request',
      'delete': 'Delete',
      'remove': 'Remove',
      'success': 'Success',
      'error': 'Error',
      'groupChatError': 'Group chat error',
      'sendImageFailed': 'Failed to send image',
      'sendFileFailed': 'Failed to send file',
      'loadPlaceListError': 'Failed to load places list',
      'mapDirections': 'Map directions',
      'tapToViewMap': 'Tap to view map',
      'fileSizeLimit': 'File size limit: 10MB',
      'searchDocument': 'Search document',
      'searchDocumentHint': 'Search documents...',
      'documentSheet': 'Documents',
      'noDocumentsFound': 'No documents found',
      'loadDocumentListFailed': 'Failed to load documents list',
      'noPlaceFoundInArea': 'No places found in area',
      'findAgain': 'Find again',
      'result': 'Result',
      'anonymous': 'Anonymous',
      'uploadFailed': 'Upload failed',
      'searchPlaceByName': 'Search place by name',
      'searchFriends': 'Search friends',
      'searchPlace': 'Search place',
      'searchGroup': 'Search group',
      'searchUser': 'Search user',
      'searchFileByName': 'Search file by name',
      'searchResults': 'Search results',
      'noResultsFound': 'No results found',
      'clearSearch': 'Clear search',
      'close': 'Close',
      'exploreTopPanel': 'Explore',
      'studyNearMe': 'Study near me',
      'pleaseLogin': 'Please sign in',
      // Missing validators
      'enterValidEmail': 'Please enter a valid email',
      'passwordMinChars': 'Password must be at least 6 characters',
      'passwordRequirements': 'Password must contain uppercase, lowercase, number and special character',
      'enterValidName': 'Please enter a valid name (min 2 characters)',
      'enterConfirmPassword': 'Please confirm your password',
      'passwordConfirmMismatch': 'Passwords do not match',
      'otp6Chars': 'OTP must be 6 digits',
      'fullName': 'Full name',
      'confirmPasswordField': 'Confirm password',
      'alreadyHaveAccount': 'Already have an account? Sign in',
      // Missing document
      'yourUploadedDocuments': 'Your uploaded documents',
      'documentsCategory': 'Document category',
      'noSearchResults': 'No results found for "{query}"',
      'cancelBtn2': 'Cancel',
      // Missing friendships
      'addFriends': 'Add friends',
      'requestSent': 'Request sent',
      'noFriends': 'No friends yet',
      'noFriendsFound': 'No friends found',
      'unfriend': 'Unfriend',
      'friendRequestSuccess': 'Friend request sent',
      'friend': 'Friend',
      'declineInvite': 'Decline invite',
      // Missing groups
      'studyGroup': 'Study group',
      'noMessages': 'No messages',
      'beFirstToSend': 'Be the first to send a message',
      'attach': 'Attach',
      'photoLibrary': 'Photo library',
      'camera': 'Camera',
      'selectFile': 'Select file',
      'shareLocation': 'Share location',
      'uploadingProgress': 'Uploading{fileName}',
      'reactToMessage': 'React to message',
      'deleteMessage': 'Delete message',
      'messageWillDeleteAll': 'This will permanently delete the message.',
      'deleteMessageConfirm': 'Delete message?',
      'deleteMessageConfirmDesc': 'You cannot recover this message after deletion.',
      'messageDeleted': 'Message deleted',
      'seen': 'Seen',
      'youShared': 'You shared',
      'sharedDocument': '{name} shared',
      'fileUploadedSuccess': 'File uploaded: {fileName}',
      'fileUploadFailed': 'File upload failed: {error}',
      'sharedFile': 'Shared file',
      'locationPlaceholder': 'Location',
      'locationShared': 'Location shared',
      'members': 'members',
      'groupsTab': 'Groups',
      'publicBadge': 'Public',
      'member': 'member',
      'groupOwner': 'Owner',
      'adminBadge': 'Admin',
      'noMessagesGroup': 'No messages in group',
      'noGroupsYet': 'No groups yet',
      'createGroupHint': 'Create a group to start studying with friends',
      'location': 'Location',
      'groupStorage': 'Storage ({count})',
      'allMembers': 'All members',
      'tryDifferentKeyword': 'Try a different keyword',
      'shareResources': 'Share resources to group',
      'imageSharedBy': '{name} shared an image',
      'placeSharedSentBy': 'Shared by {name}',
      'suggestedFriends': 'Suggested friends',
      'noUsersFound': 'No users found',
      'noFriendsList': 'No friends in list',
      'pending': 'Pending',
      'sendInviteSuccess': 'Invite sent to {name}',
      'sendInviteFailed': 'Failed to send invite',
      'invite': 'Invite',
      // Missing places
      'noAddress': 'No address',
      'searchPlaceSheet': 'Search place',
      'publicPlaces': 'Public places',
      'selectFromList': 'Select from list',
      'manualInput': 'Manual input',
      'documentId': 'Document ID',
      'shareAndToGroup': 'Share to group',
      'results': 'Results',
      'acceptInvite': 'Accept invite',
      'addPhotos': 'Add photos',
      'noPhotos': 'No photos',
      'loadDocForPlace': 'Load document for place',
      'account': 'Account',
      'address': 'Address',
      'nearby': 'Nearby',
      'pleaseTryAgain': 'Please try again',
      'removeFilter': 'Remove filter',
      'map': 'Map',
      'list': 'List',
      'filter': 'Filter',
      // Missing profile
      'profileUpdatedSuccess': 'Profile updated successfully',
      'selectPhoto': 'Select photo',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'save': 'Save',
      // Missing security
      'changePasswordSuccess': 'Password changed successfully',
      'currentPassword': 'Current password',
      'newPasswordRequired': 'New password',
    },
  };

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String _text(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;

  String _format(String key, Map<String, String> replacements) {
    var value = _text(key);
    replacements.forEach((placeholder, replacement) {
      value = value.replaceAll(placeholder, replacement);
    });
    return value;
  }

  String get appName => _text('appName');
  String get explore => _text('explore');
  String get places => _text('places');
  String get documents => _text('documents');
  String get viewContent => _text('viewContent');
  String get publishedPostsList => _text('publishedPostsList');
  String get profile => _text('profile');
  String get search => _text('search');
  String get saved => _text('saved');
  String get settings => _text('settings');
  String get notifications => _text('notifications');
  String get notificationsInApp => _text('notificationsInApp');
  String get receiveInAppNotifications => _text('receiveInAppNotifications');
  String get inAppNotificationSettings => _text('inAppNotificationSettings');
  String get notificationSettingsDescription => _text('notificationSettingsDescription');
  String get notificationsDisabled => _text('notificationsDisabled');
  String get notificationsDisabledDescription => _text('notificationsDisabledDescription');
  String get enableNotifications => _text('enableNotifications');
  String get theme => _text('theme');
  String get changePassword => _text('changePassword');
  String get language => _text('language');
  String get system => _text('system');
  String get light => _text('light');
  String get dark => _text('dark');
  String get vietnamese => _text('vietnamese');
  String get english => _text('english');
  String get useAppInVietnamese => _text('useAppInVietnamese');
  String get useAppInEnglish => _text('useAppInEnglish');
  String get editProfile => _text('editProfile');
  String get viewProfile => _text('viewProfile');
  String get bio => _text('bio');
  String get myPosts => _text('myPosts');
  String get feedback => _text('feedback');
  String get reportViolation => _text('reportViolation');
  String get signOut => _text('signOut');
  String get shareOnSfinity => _text('shareOnSfinity');
  String get shareDescription => _text('shareDescription');
  String get sharePlace => _text('sharePlace');
  String get sharePlaceSubtitle => _text('sharePlaceSubtitle');
  String get uploadStudyMaterials => _text('uploadStudyMaterials');
  String get uploadStudyMaterialsSubtitle => _text('uploadStudyMaterialsSubtitle');
  String get retry => _text('retry');
  String get searchHint => _text('searchHint');
  String get noNotifications => _text('noNotifications');
  String get markAllRead => _text('markAllRead');
  String get deleteNotification => _text('deleteNotification');
  String get deleteAllNotifications => _text('deleteAllNotifications');
  String get deleteAllNotificationsConfirm => _text('deleteAllNotificationsConfirm');
  String get deleteNotificationConfirm => _text('deleteNotificationConfirm');
  String get yesDelete => _text('yesDelete');
  String get cancel => _text('cancel');
  String get noFavoritesYet => _text('noFavoritesYet');
  String get sendFeedback => _text('sendFeedback');
  String ratingLabel(int rating) => _format('ratingLabel', {'{rating}': '$rating'});
  String get feedbackContent => _text('feedbackContent');
  String get submit => _text('submit');
  String get enterAtLeast5Characters => _text('enterAtLeast5Characters');
  String get thanksForYourFeedback => _text('thanksForYourFeedback');
  String get reportSubmitted => _text('reportSubmitted');
  String get reportViolationTitle => _text('reportViolationTitle');
  String get type => _text('type');
  String get documentType => _text('documentType');
  String get userType => _text('userType');
  String get otherType => _text('otherType');
  String get targetIdOptional => _text('targetIdOptional');
  String get reason => _text('reason');
  String get detailedDescription => _text('detailedDescription');
  String get submitReport => _text('submitReport');
  String get login => _text('login');
  String get welcomeBack => _text('welcomeBack');
  String get email => _text('email');
  String get password => _text('password');
  String get forgotPasswordQuestion => _text('forgotPasswordQuestion');
  String get orContinueWith => _text('orContinueWith');
  String get continueWithGoogle => _text('continueWithGoogle');
  String get noAccountYetRegister => _text('noAccountYetRegister');
  String get forgotPassword => _text('forgotPassword');
  String get forgotPasswordDescription => _text('forgotPasswordDescription');
  String get sendOtp => _text('sendOtp');
  String get backToSignIn => _text('backToSignIn');
  String get otpVerification => _text('otpVerification');
  String get otpDescription => _text('otpDescription');
  String get otpCode6Digits => _text('otpCode6Digits');
  String get newPassword => _text('newPassword');
  String get resetPassword => _text('resetPassword');
  String get passwordResetSuccessful => _text('passwordResetSuccessful');
  String get welcomeTitle => _text('welcomeTitle');
  String get welcomeSubtitle => _text('welcomeSubtitle');
  String get smartSearchTitle => _text('smartSearchTitle');
  String get smartSearchSubtitle => _text('smartSearchSubtitle');
  String get stayConnectedTitle => _text('stayConnectedTitle');
  String get stayConnectedSubtitle => _text('stayConnectedSubtitle');
  String get next => _text('next');
  String get getStarted => _text('getStarted');
  String get welcomeTitleShort => _text('welcomeTitleShort');
  String get welcomeDescShort => _text('welcomeDescShort');
  String get studyPlacesOrMaterials => _text('studyPlacesOrMaterials');
  String get libraryCafeStudyGroupSpace => _text('libraryCafeStudyGroupSpace');
  String get notesSlidesExamPapersSubjectSummaries => _text('notesSlidesExamPapersSubjectSummaries');
  String get createGroupTitle => _text('createGroupTitle');
  String get editGroupTitle => _text('editGroupTitle');
  String get groupNameLabel => _text('groupNameLabel');
  String get groupNameHint => _text('groupNameHint');
  String get groupDescLabel => _text('groupDescLabel');
  String get groupDescHint => _text('groupDescHint');
  String get publicGroupLabel => _text('publicGroupLabel');
  String get publicGroupHint => _text('publicGroupHint');
  String get privateGroupHint => _text('privateGroupHint');
  String get autoApproveLabel => _text('autoApproveLabel');
  String get autoApproveHint => _text('autoApproveHint');
  String get requireApprovalHint => _text('requireApprovalHint');
  String get createGroupBtn => _text('createGroupBtn');
  String get saveChangesBtn => _text('saveChangesBtn');
  String get cancelBtn => _text('cancelBtn');
  String get joinRequestsLabel => _text('joinRequestsLabel');
  String get approveBtn => _text('approveBtn');
  String get declineBtn => _text('declineBtn');
  String get welcomeDescription => _text('welcomeDescription');
  String get smartSearchDescription => _text('smartSearchDescription');
  String get stayConnectedDescription => _text('stayConnectedDescription');
  String get welcomeBadge => _text('welcomeBadge');
  String get smartSearchBadge => _text('smartSearchBadge');
  String get stayConnectedBadge => _text('stayConnectedBadge');
  String get skip => _text('skip');
  String get getStartedNow => _text('getStartedNow');
  String get invitesTab => _text('invitesTab');
  String get placeDetail => _text('placeDetail');
  String get placeUpdated => _text('placeUpdated');
  String get memberRemoved => _text('memberRemoved');
  String get registerTitle => _text('registerTitle');
  String get registerSuccess => _text('registerSuccess');
  String get register => _text('register');
  String get verifyEmail => _text('verifyEmail');
  String get understood => _text('understood');
  String get gender => _text('gender');
  String get dateOfBirth => _text('dateOfBirth');
  String get selectDateOfBirth => _text('selectDateOfBirth');
  String get personal => _text('personal');
  String get community => _text('community');
  String get documentUploadTitle => _text('documentUploadTitle');
  String get editDocument => _text('editDocument');
  String get shareToGroup => _text('shareToGroup');
  String loadDocumentFor(String name) => _format('loadDocumentFor', {'{name}': name});
  String get documentName => _text('documentName');
  String get documentNameHint => _text('documentNameHint');
  String get studyDocument => _text('studyDocument');
  String get category => _text('category');
  String get selectCategory => _text('selectCategory');
  String get publicAllSee => _text('publicAllSee');
  String get reset_ => _text('reset_');
  String get tags => _text('tags');
  String get updatePlace => _text('updatePlace');
  String get postDocument => _text('postDocument');
  String get documentUpdateSuccess => _text('documentUpdateSuccess');
  String get documentShareSuccess => _text('documentShareSuccess');
  String get documentStudyShared => _text('documentStudyShared');
  String get pdfDocument => _text('pdfDocument');
  String get tapSelectPDF => _text('tapSelectPDF');
  String get changePdf => _text('changePdf');
  String get uploadDocument => _text('uploadDocument');
  String get studyMaterials => _text('studyMaterials');
  String get documentLabel => _text('documentLabel');
  String get untitledDocument => _text('untitledDocument');
  String get shareDocument => _text('shareDocument');
  String get allFiles => _text('allFiles');
  String get images => _text('images');
  String get files => _text('files');
  String get fileName => _text('fileName');
  String get documentDetail => _text('documentDetail');
  String get uploadedDocuments => _text('uploadedDocuments');
  String get placeName => _text('placeName');
  String get placeNameRequired => _text('placeNameRequired');
  String get placeDescription => _text('placeDescription');
  String get additionalDescription => _text('additionalDescription');
  String get placeDescriptionHint => _text('placeDescriptionHint');
  String get placeDescriptionDetail => _text('placeDescriptionDetail');
  String get placeDescriptionMin => _text('placeDescriptionMin');
  String get placeWillShowMap => _text('placeWillShowMap');
  String get placeDisplayOnMap => _text('placeDisplayOnMap');
  String get saveThisPlace => _text('saveThisPlace');
  String get favoritePlace => _text('favoritePlace');
  String get unfavoritePlace => _text('unfavoritePlace');
  String get favoritePlaceCommunity => _text('favoritePlaceCommunity');
  String get unfavoritePlaceCommunity => _text('unfavoritePlaceCommunity');
  String get savedPlace => _text('savedPlace');
  String get loginToSavePlace => _text('loginToSavePlace');
  String get documentsAtPlace => _text('documentsAtPlace');
  String get noDocuments => _text('noDocuments');
  String get noDocumentsPlace => _text('noDocumentsPlace');
  String get loginToCheckin => _text('loginToCheckin');
  String get loginToCheckinDesc => _text('loginToCheckinDesc');
  String get updateGPS => _text('updateGPS');
  String get enableGPSCheckin => _text('enableGPSCheckin');
  String get enableGPSDistance => _text('enableGPSDistance');
  String get enableGPSNearMe => _text('enableGPSNearMe');
  String get yourLocation => _text('yourLocation');
  String get noYourLocation => _text('noYourLocation');
  String get cannotGetGPS => _text('cannotGetGPS');
  String get cannotGetGPSCheckin => _text('cannotGetGPSCheckin');
  String get cannotGetGPSDirections => _text('cannotGetGPSDirections');
  String get cannotGetCurrentLocation => _text('cannotGetCurrentLocation');
  String get cannotLoadDirections => _text('cannotLoadDirections');
  String get noPathFound => _text('noPathFound');
  String get noSuitableRoute => _text('noSuitableRoute');
  String get start => _text('start');
  String get continueStraight => _text('continueStraight');
  String get continue_ => _text('continue_');
  String get noLocationYet => _text('noLocationYet');
  String get cannotCreatePlace => _text('cannotCreatePlace');
  String get cannotUpdatePlace => _text('cannotUpdatePlace');
  String get invalidCoordinates => _text('invalidCoordinates');
  String get allZones => _text('allZones');
  String get filterAmenities => _text('filterAmenities');
  String get holdMapOrButton => _text('holdMapOrButton');
  String get holdMapOrPressPlus => _text('holdMapOrPressPlus');
  String get selectedLocation => _text('selectedLocation');
  String get myPlaces => _text('myPlaces');
  String get communityPlaces => _text('communityPlaces');
  String get saveNewPlace => _text('saveNewPlace');
  String get savePlace => _text('savePlace');
  String get editPlace => _text('editPlace');
  String get deletePlace => _text('deletePlace');
  String get deletePlaceConfirm => _text('deletePlaceConfirm');
  String get deletePlaceDesc => _text('deletePlaceDesc');
  String get placeDeleted => _text('placeDeleted');
  String get placeNotFound => _text('placeNotFound');
  String get viewOnMap => _text('viewOnMap');
  String get viewPlaceDetail => _text('viewPlaceDetail');
  String get managePlace => _text('managePlace');
  String get noPlace => _text('noPlace');
  String get noPlaceCommunity => _text('noPlaceCommunity');
  String get noPlaceYet => _text('noPlaceYet');
  String get noPlaceFilter => _text('noPlaceFilter');
  String get addFirstPlace => _text('addFirstPlace');
  String get noPlaceFound => _text('noPlaceFound');
  String get groupCreated => _text('groupCreated');
  String get groupNotFound => _text('groupNotFound');
  String get addMembers => _text('addMembers');
  String get leaveGroup => _text('leaveGroup');
  String get leaveGroup2 => _text('leaveGroup2');
  String get leaveGroupConfirm => _text('leaveGroupConfirm');
  String get leaveGroupBtn => _text('leaveGroupBtn');
  String get disband => _text('disband');
  String get disbandGroup => _text('disbandGroup');
  String get disbandGroupConfirm => _text('disbandGroupConfirm');
  // confirmDisbandGroup - method version with group name parameter
  String disbandGroupWithName(String name) => '$name ${_text('confirmDisbandGroup')}';
  String get confirm => _text('confirm');
  String get selectNewOwnerTitle => _text('selectNewOwnerTitle');
  String get mustTransferOwnership => _text('mustTransferOwnership');
  String get memberNotFound => _text('memberNotFound');
  String get searchMembers => _text('searchMembers');
  String get publicGroup => _text('publicGroup');
  String get privateGroup => _text('privateGroup');
  String get groupOptions => _text('groupOptions');
  String get groupChatTab => _text('groupChatTab');
  String get groupStorageTab => _text('groupStorageTab');
  String get groupMembersTab => _text('groupMembersTab');
  String get deleteMemberConfirm => _text('deleteMemberConfirm');
  String get cannotRemoveMember => _text('cannotRemoveMember');
  String get inviteToGroup => _text('inviteToGroup');
  // groupMembers - method version with count parameter
  String groupMembers(int count) => '${_text('groupMembers')} ($count)';
  String get studyGroups => _text('studyGroups');
  String get myGroups => _text('myGroups');
  String get exploreGroups => _text('exploreGroups');
  String get friends => _text('friends');
  String get createGroup => _text('createGroup');
  // inviteReceived - method version with count
  String inviteReceived(int count) => '${_text('inviteReceived')} ($count)';
  String get groupStudy => _text('groupStudy');
  String get someone => _text('someone');
  String get invitedYou => _text('invitedYou');
  // Group success/failure methods with optional name parameter
  String declineInviteSuccess([String? name]) => name != null && name.isNotEmpty
      ? '$name ${_text('declineInviteSuccess')}'
      : _text('declineInviteSuccess');
  String declineInviteFailed([String? name]) => name != null && name.isNotEmpty
      ? '$name ${_text('declineInviteFailed')}'
      : _text('declineInviteFailed');
  String acceptInviteSuccess([String? name]) => name != null && name.isNotEmpty
      ? '$name ${_text('acceptInviteSuccess')}'
      : _text('acceptInviteSuccess');
  String acceptInviteFailed([String? name]) => name != null && name.isNotEmpty
      ? '$name ${_text('acceptInviteFailed')}'
      : _text('acceptInviteFailed');
  String joinGroupSuccess(String name) => '$name ${_text('joinGroupSuccess')}';
  String joinGroupPending(String name) => '$name ${_text('joinGroupPending')}';
  String cancelRequestSuccess(String name) => '$name ${_text('cancelRequestSuccess')}';
  String get noGroupsYet2 => _text('noGroupsYet2');
  String get noGroupsNewExplore => _text('noGroupsNewExplore');
  String get noGroupsMatch => _text('noGroupsMatch');
  String get searchPublicGroups => _text('searchPublicGroups');
  String get errorOccurred => _text('errorOccurred');
  String get groupChat => _text('groupChat');
  String get decline => _text('decline');
  String get accept => _text('accept');
  String get noInvites => _text('noInvites');
  String get friendRequests => _text('friendRequests');
  // sentRequests - method version with count parameter
  String sentRequests(int count) => '${_text('sentRequests')} ($count)';
  String get friendsTab => _text('friendsTab');
  String get discoverTab => _text('discoverTab');
  // Document methods with parameters (called as methods with error details)
  String cannotOpenPDF([String? error]) => error != null && error.isNotEmpty
      ? '${_text('cannotOpenPDF')}: $error'
      : _text('cannotOpenPDF');
  String cannotConnectServer([String? error]) => error != null && error.isNotEmpty
      ? '${_text('cannotConnectServer')}: $error'
      : _text('cannotConnectServer');
  String get favoriteDocument => _text('favoriteDocument');
  String get unfavoriteDocument => _text('unfavoriteDocument');
  String get noDownloadLink => _text('noDownloadLink');
  String get openDocumentSuccess => _text('openDocumentSuccess');
  String cannotOpenDocument([String? error]) => error != null && error.isNotEmpty
      ? '${_text('cannotOpenDocument')}: $error'
      : _text('cannotOpenDocument');
  String get rateDocumentSuccess => _text('rateDocumentSuccess');
  String rateDocumentFailed([String? error]) => error != null && error.isNotEmpty
      ? '${_text('rateDocumentFailed')}: $error'
      : _text('rateDocumentFailed');
  String get ratingDeleted => _text('ratingDeleted');
  String cannotDeleteRating([String? error]) => error != null && error.isNotEmpty
      ? '${_text('cannotDeleteRating')}: $error'
      : _text('cannotDeleteRating');
  String get noRating => _text('noRating');
  String get loading => _text('loading');
  String get noResourceFound => _text('noResourceFound');
  String get relatedTags => _text('relatedTags');
  String get ratingAndComments => _text('ratingAndComments');
  String get yourRating => _text('yourRating');
  String get sendRating => _text('sendRating');
  String get ratingHint => _text('ratingHint');
  String get noComments => _text('noComments');
  String get all => _text('all');
  String get newest => _text('newest');
  String get noCommentsFound => _text('noCommentsFound');
  String get loadMoreComments => _text('loadMoreComments');
  String get download => _text('download');
  String get share => _text('share');
  String get communityContent => _text('communityContent');
  String get searchGroupHint => _text('searchGroupHint');
  String get noGroupsExplore => _text('noGroupsExplore');
  String get noGroupsFound => _text('noGroupsFound');
  String get searchUserByNameEmail => _text('searchUserByNameEmail');
  String get cancelRequest => _text('cancelRequest');
  String get noFriendsSearchHint => _text('noFriendsSearchHint');
  String get noUserFound => _text('noUserFound');
  String get searchByNameEmail => _text('searchByNameEmail');
  String get friendRequestSent => _text('friendRequestSent');
  String get friendRequestError => _text('friendRequestError');
  String get delete => _text('delete');
  String get remove => _text('remove');
  String get success => _text('success');
  String get error => _text('error');
  // Group chat error - method version with optional error parameter
  String groupChatError([String? error]) => error != null && error.isNotEmpty
      ? '${_text('groupChatError')}: $error'
      : _text('groupChatError');
  // sendImageFailed - method version with optional error parameter
  String sendImageFailed([String? error]) => error != null && error.isNotEmpty
      ? '${_text('sendImageFailed')}: $error'
      : _text('sendImageFailed');
  // sendFileFailed - method version with optional error parameter
  String sendFileFailed([String? error]) => error != null && error.isNotEmpty
      ? '${_text('sendFileFailed')}: $error'
      : _text('sendFileFailed');
  // loadPlaceListError - method version with optional error parameter
  String loadPlaceListError([String? error]) => error != null && error.isNotEmpty
      ? '${_text('loadPlaceListError')}: $error'
      : _text('loadPlaceListError');
  String get mapDirections => _text('mapDirections');
  String get tapToViewMap => _text('tapToViewMap');
  String get fileSizeLimit => _text('fileSizeLimit');
  String get searchDocument => _text('searchDocument');
  String get searchDocumentHint => _text('searchDocumentHint');
  String get documentSheet => _text('documentSheet');
  String get noDocumentsFound => _text('noDocumentsFound');
  String get loadDocumentListFailed => _text('loadDocumentListFailed');
  String get noPlaceFoundInArea => _text('noPlaceFoundInArea');
  String get findAgain => _text('findAgain');
  String get result => _text('result');
  String get anonymous => _text('anonymous');
  String get uploadFailed => _text('uploadFailed');
  String get searchPlaceByName => _text('searchPlaceByName');
  String get searchFriends => _text('searchFriends');
  String get searchPlace => _text('searchPlace');
  String get searchGroup => _text('searchGroup');
  String get searchMember => _text('searchMember');
  String get searchUser => _text('searchUser');
  String get searchFileByName => _text('searchFileByName');
  String get searchResults => _text('searchResults');
  String get noResultsFound => _text('noResultsFound');
  String get clearSearch => _text('clearSearch');
  String get close => _text('close');
  String get exploreTopPanel => _text('exploreTopPanel');
  String get studyNearMe => _text('studyNearMe');
  String get pleaseLogin => _text('pleaseLogin');
  String get apiError => _text('apiError');
  // Missing validators getters
  String get enterValidEmail => _text('enterValidEmail');
  String get passwordMinChars => _text('passwordMinChars');
  String get passwordRequirements => _text('passwordRequirements');
  String get enterValidName => _text('enterValidName');
  String get enterConfirmPassword => _text('enterConfirmPassword');
  String get passwordConfirmMismatch => _text('passwordConfirmMismatch');
  String get otp6Chars => _text('otp6Chars');
  String get fullName => _text('fullName');
  String get confirmPasswordField => _text('confirmPasswordField');
  String get alreadyHaveAccount => _text('alreadyHaveAccount');
  // Missing document getters
  String get yourUploadedDocuments => _text('yourUploadedDocuments');
  String get documentsCategory => _text('documentsCategory');
  String get cancelBtn2 => _text('cancelBtn2');
  // Document methods with parameters
  String noSearchResults(String query) => _format('noSearchResults', {'{query}': query});
  // Missing friendships getters
  String get addFriends => _text('addFriends');
  String get requestSent => _text('requestSent');
  String get noFriends => _text('noFriends');
  String get noFriendsFound => _text('noFriendsFound');
  String get unfriend => _text('unfriend');
  String get friendRequestSuccess => _text('friendRequestSuccess');
  String get friend => _text('friend');
  String get declineInvite => _text('declineInvite');
  // Missing groups getters
  String get studyGroup => _text('studyGroup');
  String get noMessages => _text('noMessages');
  String get beFirstToSend => _text('beFirstToSend');
  String get attach => _text('attach');
  String get photoLibrary => _text('photoLibrary');
  String get camera => _text('camera');
  String get selectFile => _text('selectFile');
  String get shareLocation => _text('shareLocation');
  String get reactToMessage => _text('reactToMessage');
  String get deleteMessage => _text('deleteMessage');
  String get messageWillDeleteAll => _text('messageWillDeleteAll');
  String get deleteMessageConfirm => _text('deleteMessageConfirm');
  String get deleteMessageConfirmDesc => _text('deleteMessageConfirmDesc');
  String get messageDeleted => _text('messageDeleted');
  String get seen => _text('seen');
  String get youShared => _text('youShared');
  String get sharedFile => _text('sharedFile');
  String get locationPlaceholder => _text('locationPlaceholder');
  String get locationShared => _text('locationShared');
  String get members => _text('members');
  String get groupsTab => _text('groupsTab');
  String get publicBadge => _text('publicBadge');
  String get member => _text('member');
  String get groupOwner => _text('groupOwner');
  String get adminBadge => _text('adminBadge');
  String get noMessagesGroup => _text('noMessagesGroup');
  String get noGroupsYet => _text('noGroupsYet');
  String get createGroupHint => _text('createGroupHint');
  String get location => _text('location');
  String get allMembers => _text('allMembers');
  String get tryDifferentKeyword => _text('tryDifferentKeyword');
  String get shareResources => _text('shareResources');
  String get suggestedFriends => _text('suggestedFriends');
  String get noUsersFound => _text('noUsersFound');
  String get noFriendsList => _text('noFriendsList');
  String get pending => _text('pending');
  String get sendInviteFailed => _text('sendInviteFailed');
  String get invite => _text('invite');
  // Missing groups methods
  String uploadingProgress(String? fileName) => _format('uploadingProgress', {'{fileName}': fileName ?? ''});
  String sharedDocument(String name) => _format('sharedDocument', {'{name}': name});
  String fileUploadedSuccess(String fileName) => _format('fileUploadedSuccess', {'{fileName}': fileName});
  String fileUploadFailed(String error) => _format('fileUploadFailed', {'{error}': error});
  String groupStorage(int count) => _format('groupStorage', {'{count}': '$count'});
  String imageSharedBy(String name, String senderName) => _format('imageSharedBy', {'{name}': name, '{senderName}': senderName});
  String placeSharedSentBy(String name) => _format('placeSharedSentBy', {'{name}': name});
  String sendInviteSuccess(String name) => _format('sendInviteSuccess', {'{name}': name});
  // Missing places getters
  String get noAddress => _text('noAddress');
  String get searchPlaceSheet => _text('searchPlaceSheet');
  String get publicPlaces => _text('publicPlaces');
  String get selectFromList => _text('selectFromList');
  String get manualInput => _text('manualInput');
  String get documentId => _text('documentId');
  String get shareAndToGroup => _text('shareAndToGroup');
  String get results => _text('results');
  String get acceptInvite => _text('acceptInvite');
  String get addPhotos => _text('addPhotos');
  String get noPhotos => _text('noPhotos');
  String get loadDocForPlace => _text('loadDocForPlace');
  String get account => _text('account');
  String get address => _text('address');
  String get nearby => _text('nearby');
  String get pleaseTryAgain => _text('pleaseTryAgain');
  String get removeFilter => _text('removeFilter');
  String get map => _text('map');
  String get list => _text('list');
  String get filter => _text('filter');
  // Missing profile getters
  String get profileUpdatedSuccess => _text('profileUpdatedSuccess');
  String get selectPhoto => _text('selectPhoto');
  String get male => _text('male');
  String get female => _text('female');
  String get other => _text('other');
  String get save => _text('save');
  // Missing security getters
  String get changePasswordSuccess => _text('changePasswordSuccess');
  String get currentPassword => _text('currentPassword');
  String get newPasswordRequired => _text('newPasswordRequired');
  // Method for offline profile load
  String offlineProfileLoad(String err) => _format('offlineProfileLoad', {'{name}': err});
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

