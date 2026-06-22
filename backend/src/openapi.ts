/** OpenAPI 3.0 — mirrors live routes under `/api` for Swagger UI. */
export const openApiDocument = {
  openapi: '3.0.3',
  info: {
    title: 'Sfinity API',
    version: '0.1.0',
    description:
      'REST API for Sfinity mobile & web-admin. Same contract as previous NestJS backend.',
  },
  servers: [{ url: '/', description: 'Current host' }],
  tags: [
    { name: 'auth' },
    { name: 'users' },
    { name: 'categories' },
    { name: 'document' },
    { name: 'places' },
    { name: 'favorites' },
    { name: 'feedback' },
    { name: 'reports' },
    { name: 'notifications' },
    { name: 'admin' },
    { name: 'friends' },
    { name: 'groups' },
    { name: 'payments' },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
    schemas: {
      LoginDto: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 6 },
        },
      },
      RegisterDto: {
        type: 'object',
        required: ['email', 'password', 'name'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 6 },
          name: { type: 'string', minLength: 2 },
        },
      },
      ForgotPasswordDto: {
        type: 'object',
        required: ['email'],
        properties: { email: { type: 'string', format: 'email' } },
      },
      ResetPasswordDto: {
        type: 'object',
        required: ['email', 'code', 'newPassword'],
        properties: {
          email: { type: 'string', format: 'email' },
          code: { type: 'string', minLength: 6, maxLength: 6 },
          newPassword: { type: 'string', minLength: 6 },
        },
      },
      UpdateProfileDto: {
        type: 'object',
        required: ['name'],
        properties: {
          name: { type: 'string', minLength: 2 },
          avatar: { type: 'string' },
        },
      },
      UserRecord: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          email: { type: 'string' },
          name: { type: 'string' },
          avatar: { type: 'string', nullable: true },
          role: { type: 'string' },
          status: { type: 'string' },
          notificationsEnabled: { type: 'boolean' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      ChangePasswordDto: {
        type: 'object',
        required: ['currentPassword', 'newPassword'],
        properties: {
          currentPassword: { type: 'string', minLength: 6 },
          newPassword: { type: 'string', minLength: 6 },
        },
      },
      CreateAdminDto: {
        type: 'object',
        required: ['email', 'password', 'name'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 6 },
          name: { type: 'string', minLength: 2 },
        },
      },
      UpdateUserDto: {
        type: 'object',
        properties: {
          name: { type: 'string', minLength: 2 },
          role: { type: 'string', enum: ['USER', 'ADMIN'] },
          status: { type: 'string', enum: ['ACTIVE', 'BANNED'] },
        },
      },
      CreateCategoryDto: {
        type: 'object',
        required: ['name', 'slug'],
        properties: {
          name: { type: 'string', minLength: 2 },
          slug: { type: 'string', minLength: 2 },
          description: { type: 'string' },
        },
      },
      UpdateCategoryDto: {
        type: 'object',
        properties: {
          name: { type: 'string', minLength: 2 },
          slug: { type: 'string', minLength: 2 },
          description: { type: 'string' },
        },
      },
      CreateDocumentDto: {
        type: 'object',
        required: ['title', 'body'],
        properties: {
          title: { type: 'string', minLength: 2 },
          body: { type: 'string' },
          status: { type: 'string', enum: ['DRAFT', 'PUBLISHED'] },
          categoryId: { type: 'string' },
          placeId: { type: 'string', description: 'Place ID if uploaded at a place' },
          fileUrl: { type: 'string' },
          fileType: { type: 'string' },
          fileSize: { type: 'number' },
          subjectCode: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } },
        },
      },
      UpdateDocumentDto: {
        type: 'object',
        properties: {
          title: { type: 'string', minLength: 2 },
          body: { type: 'string' },
          status: { type: 'string', enum: ['DRAFT', 'PUBLISHED'] },
          categoryId: { type: 'string', nullable: true },
          placeId: { type: 'string', nullable: true },
        },
      },
      CreatePlaceDto: {
        type: 'object',
        required: ['title', 'latitude', 'longitude'],
        properties: {
          title: { type: 'string', minLength: 2 },
          body: { type: 'string' },
          status: { type: 'string', enum: ['DRAFT', 'PUBLISHED', 'PENDING'] },
          latitude: { type: 'number' },
          longitude: { type: 'number' },
          address: { type: 'string' },
          zone: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } },
        },
      },
      UpdatePlaceDto: {
        type: 'object',
        properties: {
          title: { type: 'string', minLength: 2 },
          body: { type: 'string', nullable: true },
          status: { type: 'string', enum: ['DRAFT', 'PUBLISHED', 'PENDING'] },
          latitude: { type: 'number', nullable: true },
          longitude: { type: 'number', nullable: true },
          address: { type: 'string', nullable: true },
          zone: { type: 'string', nullable: true },
          tags: { type: 'array', items: { type: 'string' } },
        },
      },
      CreateFeedbackDto: {
        type: 'object',
        required: ['message'],
        properties: {
          message: { type: 'string', minLength: 5 },
          rating: { type: 'integer', minimum: 1, maximum: 5 },
        },
      },
      ReplyFeedbackDto: {
        type: 'object',
        required: ['reply'],
        properties: { reply: { type: 'string', minLength: 2 } },
      },
      CreateReportDto: {
        type: 'object',
        required: ['targetType', 'reason'],
        properties: {
          targetType: { type: 'string', minLength: 2 },
          targetId: { type: 'string' },
          reason: { type: 'string', minLength: 2 },
          description: { type: 'string' },
        },
      },
      ResolveReportDto: {
        type: 'object',
        required: ['status'],
        properties: {
          status: { type: 'string', enum: ['PENDING', 'RESOLVED', 'REJECTED'] },
          resolution: { type: 'string' },
        },
      },
      CreateNotificationDto: {
        type: 'object',
        required: ['title', 'body'],
        properties: {
          title: { type: 'string', minLength: 2 },
          body: { type: 'string', minLength: 2 },
          userId: { type: 'string' },
        },
      },
      CreateMomoPaymentDto: {
        type: 'object',
        required: ['planId', 'cycle'],
        properties: {
          planId: { type: 'string', enum: ['pro'] },
          cycle: { type: 'string', enum: ['monthly', 'yearly'] },
        },
      },
    },
  },
  paths: {
    '/api/auth/login': {
      post: {
        tags: ['auth'],
        summary: 'User login',
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/LoginDto' } },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/admin/login': {
      post: {
        tags: ['auth'],
        summary: 'Admin login',
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/LoginDto' } },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/register': {
      post: {
        tags: ['auth'],
        summary: 'Register',
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/RegisterDto' } },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/forgot-password': {
      post: {
        tags: ['auth'],
        summary: 'Forgot password (demo OTP)',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ForgotPasswordDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/reset-password': {
      post: {
        tags: ['auth'],
        summary: 'Reset password with OTP',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ResetPasswordDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/me': {
      get: {
        tags: ['auth'],
        summary: 'Current user profile',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/profile': {
      patch: {
        tags: ['auth'],
        summary: 'Update profile',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/UpdateProfileDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/auth/change-password': {
      post: {
        tags: ['auth'],
        summary: 'Change password',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ChangePasswordDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/users': {
      get: {
        tags: ['users'],
        summary: 'List users (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/users/admin': {
      post: {
        tags: ['users'],
        summary: 'Create admin user',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateAdminDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/users/{id}': {
      get: {
        tags: ['users'],
        summary: 'Get user (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
      patch: {
        tags: ['users'],
        summary: 'Update user (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/UpdateUserDto' } },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      delete: {
        tags: ['users'],
        summary: 'Delete user (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/categories': {
      get: {
        tags: ['categories'],
        summary: 'List categories',
        responses: { '200': { description: 'OK' } },
      },
      post: {
        tags: ['categories'],
        summary: 'Create category (admin)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateCategoryDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/categories/{id}': {
      get: {
        tags: ['categories'],
        summary: 'Get category',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
      patch: {
        tags: ['categories'],
        summary: 'Update category (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/UpdateCategoryDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      delete: {
        tags: ['categories'],
        summary: 'Delete category (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/document/test-moderation': {
      post: {
        tags: ['document'],
        summary: 'Test PDF text extraction & OpenAI content moderation',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  title: { type: 'string' },
                  body: { type: 'string' },
                  fileUrl: { type: 'string', description: 'URL of the PDF file' },
                },
              },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/document': {
      get: {
        tags: ['document'],
        summary: 'List document (paginated)',
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'status', in: 'query', schema: { type: 'string' } },
          { name: 'categoryId', in: 'query', schema: { type: 'string' } },
          { name: 'authorId', in: 'query', schema: { type: 'string' } },
          { name: 'placeId', in: 'query', schema: { type: 'string' } },
          { name: 'tags', in: 'query', schema: { type: 'string' } },
          { name: 'page', in: 'query', schema: { type: 'string' } },
          { name: 'limit', in: 'query', schema: { type: 'string' } },
          { name: 'publishedOnly', in: 'query', schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
      post: {
        tags: ['document'],
        summary: 'Create document',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateDocumentDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/document/{id}': {
      get: {
        tags: ['document'],
        summary: 'Get document',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
      patch: {
        tags: ['document'],
        summary: 'Update document',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/UpdateDocumentDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      delete: {
        tags: ['document'],
        summary: 'Delete document',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/document/{id}/publish': {
      patch: {
        tags: ['document'],
        summary: 'Publish (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/document/{id}/unpublish': {
      patch: {
        tags: ['document'],
        summary: 'Unpublish (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/places': {
      get: {
        tags: ['places'],
        summary: 'List places (paginated)',
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'status', in: 'query', schema: { type: 'string' } },
          { name: 'authorId', in: 'query', schema: { type: 'string' } },
          {
            name: 'tags',
            in: 'query',
            schema: { type: 'string' },
            description: 'Comma-separated place tags',
          },
          { name: 'zone', in: 'query', schema: { type: 'string' } },
          { name: 'lat', in: 'query', schema: { type: 'number' } },
          { name: 'lng', in: 'query', schema: { type: 'number' } },
          { name: 'radiusKm', in: 'query', schema: { type: 'number', default: 25 } },
          { name: 'page', in: 'query', schema: { type: 'string' } },
          { name: 'limit', in: 'query', schema: { type: 'string' } },
          { name: 'publishedOnly', in: 'query', schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
      post: {
        tags: ['places'],
        summary: 'Create place',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreatePlaceDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/places/{id}': {
      get: {
        tags: ['places'],
        summary: 'Get place',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
      patch: {
        tags: ['places'],
        summary: 'Update place',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/UpdatePlaceDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      delete: {
        tags: ['places'],
        summary: 'Delete place',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/places/{id}/publish': {
      patch: {
        tags: ['places'],
        summary: 'Publish place (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/places/{id}/unpublish': {
      patch: {
        tags: ['places'],
        summary: 'Unpublish place (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/favorites': {
      get: {
        tags: ['favorites'],
        summary: 'My favorites',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/favorites/{documentId}': {
      post: {
        tags: ['favorites'],
        summary: 'Add favorite',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'documentId', in: 'path', required: true, schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
      delete: {
        tags: ['favorites'],
        summary: 'Remove favorite',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'documentId', in: 'path', required: true, schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/feedback': {
      post: {
        tags: ['feedback'],
        summary: 'Submit feedback',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateFeedbackDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      get: {
        tags: ['feedback'],
        summary: 'List feedback (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'resolved', in: 'query', schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/feedback/{id}/reply': {
      patch: {
        tags: ['feedback'],
        summary: 'Reply feedback (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ReplyFeedbackDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/feedback/{id}/resolve': {
      patch: {
        tags: ['feedback'],
        summary: 'Resolve feedback (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/reports': {
      post: {
        tags: ['reports'],
        summary: 'Create report',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateReportDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      get: {
        tags: ['reports'],
        summary: 'List reports (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'status', in: 'query', schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/reports/{id}/resolve': {
      patch: {
        tags: ['reports'],
        summary: 'Resolve report (admin)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ResolveReportDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/notifications/admin/history': {
      get: {
        tags: ['notifications'],
        summary: 'Notification history (admin)',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/notifications/admin/send': {
      post: {
        tags: ['notifications'],
        summary: 'Send notification (admin)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateNotificationDto' },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/notifications': {
      get: {
        tags: ['notifications'],
        summary: 'My notifications',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/notifications/read-all': {
      patch: {
        tags: ['notifications'],
        summary: 'Mark all read',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/notifications/{id}/read': {
      patch: {
        tags: ['notifications'],
        summary: 'Mark one read',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/admin/dashboard/stats': {
      get: {
        tags: ['admin'],
        summary: 'Dashboard stats',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/friends': {
      get: {
        tags: ['friends'],
        summary: 'List friends',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/friends/pending': {
      get: {
        tags: ['friends'],
        summary: 'List pending friend requests',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/friends/search': {
      get: {
        tags: ['friends'],
        summary: 'Search users to add as friends',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'q', in: 'query', required: true, schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/friends/request': {
      post: {
        tags: ['friends'],
        summary: 'Send friend request',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['addresseeId'],
                properties: { addresseeId: { type: 'string' } },
              },
            },
          },
        },
        responses: { '201': { description: 'Created' } },
      },
    },
    '/api/friends/{id}/respond': {
      patch: {
        tags: ['friends'],
        summary: 'Respond to friend request (accept/reject)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['action'],
                properties: { action: { type: 'string', enum: ['accept', 'reject'] } },
              },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/friends/{id}': {
      delete: {
        tags: ['friends'],
        summary: 'Unfriend / cancel request',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/groups': {
      get: {
        tags: ['groups'],
        summary: 'List user\'s groups',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
      post: {
        tags: ['groups'],
        summary: 'Create group',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name'],
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  isPublic: { type: 'boolean' },
                },
              },
            },
          },
        },
        responses: { '201': { description: 'Created' } },
      },
    },
    '/api/groups/discover': {
      get: {
        tags: ['groups'],
        summary: 'Discover public groups',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/groups/{id}': {
      get: {
        tags: ['groups'],
        summary: 'Get group details',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
      patch: {
        tags: ['groups'],
        summary: 'Update group details',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  isPublic: { type: 'boolean' },
                },
              },
            },
          },
        },
        responses: { '200': { description: 'OK' } },
      },
      delete: {
        tags: ['groups'],
        summary: 'Delete group',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/groups/{id}/join': {
      post: {
        tags: ['groups'],
        summary: 'Join a public group',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '201': { description: 'Created' } },
      },
    },
    '/api/groups/{id}/leave': {
      post: {
        tags: ['groups'],
        summary: 'Leave a group',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/groups/{id}/members': {
      post: {
        tags: ['groups'],
        summary: 'Add member to group',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['userId'],
                properties: { userId: { type: 'string' } },
              },
            },
          },
        },
        responses: { '201': { description: 'Created' } },
      },
    },
    '/api/groups/{id}/members/{uid}': {
      delete: {
        tags: ['groups'],
        summary: 'Remove member from group',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
          { name: 'uid', in: 'path', required: true, schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/payments/momo/create': {
      post: {
        tags: ['payments'],
        summary: 'Create a MoMo payment request for VIP plan',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateMomoPaymentDto' },
            },
          },
        },
        responses: {
          '200': { description: 'MoMo payUrl + deeplink returned' },
          '400': { description: 'Bad request' },
          '401': { description: 'Unauthorized' },
          '502': { description: 'MoMo rejected the request' },
          '503': { description: 'MoMo not configured on server' },
        },
      },
    },
    '/api/payments/momo/ipn': {
      post: {
        tags: ['payments'],
        summary: 'MoMo IPN webhook (server-to-server). HMAC verified internally.',
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { type: 'object' } } },
        },
        responses: { '200': { description: 'Always 200; body has resultCode/message' } },
      },
    },
    '/api/payments/momo/status/{orderId}': {
      get: {
        tags: ['payments'],
        summary: 'Check status of a MoMo transaction',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'orderId', in: 'path', required: true, schema: { type: 'string' } },
        ],
        responses: { '200': { description: 'Transaction status' } },
      },
    },
    '/api/payments/subscription/me': {
      get: {
        tags: ['payments'],
        summary: 'Current VIP subscription status for the user',
        security: [{ bearerAuth: [] }],
        responses: { '200': { description: 'VIP status' } },
      },
    },
  },
};
