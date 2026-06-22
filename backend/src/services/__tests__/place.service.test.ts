import { placeService } from '../place.service';
import { checkContentModeration } from '../../lib/moderation';
import { settingsService } from '../settings.service';
import { ContentModerationStatus, ContentVisibility, UserRole } from '../../types/enums';

// Mock Firestore
const mockDocSet = jest.fn().mockResolvedValue(undefined);
const mockDocUpdate = jest.fn().mockResolvedValue(undefined);
const mockDocGet = jest.fn().mockResolvedValue({
  exists: true,
  id: 'place-123',
  data: () => ({
    id: 'place-123',
    title: 'Original Title',
    body: 'Original Body',
    address: 'Original Address',
    authorId: 'author-123',
    visibility: ContentVisibility.PUBLIC,
    moderationStatus: ContentModerationStatus.APPROVED,
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
});

const mockDoc = jest.fn().mockReturnValue({
  set: mockDocSet,
  update: mockDocUpdate,
  get: mockDocGet,
});

const mockCollection = jest.fn().mockReturnValue({
  doc: mockDoc,
  get: jest.fn().mockResolvedValue({
    docs: [],
    size: 0,
  }),
  where: jest.fn().mockReturnThis(),
});

jest.mock('../../lib/firebase', () => ({
  getDb: () => ({
    collection: mockCollection,
  }),
}));

// Mock settingsService
jest.mock('../settings.service', () => ({
  settingsService: {
    get: jest.fn().mockResolvedValue({
      autoApprovePlaces: false,
    }),
  },
}));

// Mock checkContentModeration
jest.mock('../../lib/moderation', () => ({
  checkContentModeration: jest.fn(),
}));

describe('placeService - AI Moderation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    it('should automatically approve the place if AI moderation is clean (flagged: false)', async () => {
      (checkContentModeration as jest.Mock).mockResolvedValue({
        flagged: false,
        categories: [],
      });

      const dto = {
        title: 'Thư viện Tạ Quang Bửu',
        body: 'Không gian học tập yên tĩnh, thoáng mát',
        latitude: 21.0031,
        longitude: 105.8431,
        address: 'Đại Cồ Việt, Hai Bà Trưng, Hà Nội',
        visibility: ContentVisibility.PUBLIC,
      };

      await placeService.create('author-123', dto, UserRole.USER);

      expect(checkContentModeration).toHaveBeenCalledWith(
        'Thư viện Tạ Quang Bửu Không gian học tập yên tĩnh, thoáng mát Đại Cồ Việt, Hai Bà Trưng, Hà Nội'
      );
      expect(mockDocSet).toHaveBeenCalledWith(
        expect.objectContaining({
          moderationStatus: ContentModerationStatus.APPROVED,
          aiRejected: false,
          rejectionReason: null,
        })
      );
    });

    it('should reject the place if AI moderation flags the content (flagged: true)', async () => {
      (checkContentModeration as jest.Mock).mockResolvedValue({
        flagged: true,
        categories: ['harassment', 'toxic_keyword'],
      });

      const dto = {
        title: 'Địa điểm xấu con cặc',
        body: 'Nội dung bậy bạ',
        latitude: 21.0031,
        longitude: 105.8431,
        address: 'Hà Nội',
        visibility: ContentVisibility.PUBLIC,
      };

      await placeService.create('author-123', dto, UserRole.USER);

      expect(mockDocSet).toHaveBeenCalledWith(
        expect.objectContaining({
          moderationStatus: ContentModerationStatus.REJECTED,
          aiRejected: true,
          rejectionReason: expect.stringContaining('Tự động từ chối bởi AI. Vi phạm danh mục: harassment, toxic_keyword'),
        })
      );
    });

    it('should fall back to PENDING if AI moderation returns an error', async () => {
      (checkContentModeration as jest.Mock).mockResolvedValue({
        flagged: false,
        categories: [],
        error: 'Quota exceeded',
      });

      const dto = {
        title: 'Địa điểm bình thường',
        body: 'Không sao cả',
        latitude: 21.0031,
        longitude: 105.8431,
        address: 'Hà Nội',
        visibility: ContentVisibility.PUBLIC,
      };

      await placeService.create('author-123', dto, UserRole.USER);

      expect(mockDocSet).toHaveBeenCalledWith(
        expect.objectContaining({
          moderationStatus: ContentModerationStatus.PENDING,
          aiRejected: false,
          rejectionReason: expect.stringContaining('Lỗi hệ thống khi kiểm duyệt tự động: Quota exceeded'),
        })
      );
    });
  });

  describe('update', () => {
    it('should re-moderate and auto-approve place on content changes', async () => {
      (checkContentModeration as jest.Mock).mockResolvedValue({
        flagged: false,
        categories: [],
      });

      const dto = {
        title: 'Tên mới sạch',
        body: 'Mô tả mới',
      };

      await placeService.update('place-123', dto, 'author-123', UserRole.USER);

      expect(checkContentModeration).toHaveBeenCalledWith(
        'Tên mới sạch Mô tả mới Original Address'
      );
      expect(mockDocUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          moderationStatus: ContentModerationStatus.APPROVED,
          aiRejected: null,
          rejectionReason: null,
        })
      );
    });

    it('should re-moderate and reject place on content changes that contain flagged keywords', async () => {
      (checkContentModeration as jest.Mock).mockResolvedValue({
        flagged: true,
        categories: ['toxic_keyword'],
      });

      const dto = {
        title: 'Tên mới con cặc',
      };

      await placeService.update('place-123', dto, 'author-123', UserRole.USER);

      expect(mockDocUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          moderationStatus: ContentModerationStatus.REJECTED,
          aiRejected: true,
          rejectionReason: expect.stringContaining('Tự động từ chối bởi AI. Vi phạm danh mục: toxic_keyword'),
        })
      );
    });
  });
});
