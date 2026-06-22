import multer from 'multer';

const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5 MB

export const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_MIMES.includes(file.mimetype)) {
      cb(new Error('Chỉ hỗ trợ file ảnh: JPEG, PNG, GIF, WebP'));
      return;
    }
    cb(null, true);
  },
  limits: { fileSize: MAX_SIZE },
});
