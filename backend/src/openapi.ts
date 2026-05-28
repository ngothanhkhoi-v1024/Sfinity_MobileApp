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
    { name: 'favorites' },
    { name: 'feedback' },
    { name: 'reports' },
    { name: 'notifications' },
    { name: 'admin' },
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
          body: { type: 'string', minLength: 2 },
          status: { type: 'string', enum: ['DRAFT', 'PUBLISHED'] },
          categoryId: { type: 'string' },
          type: { type: 'string', enum: ['document', 'place'] },
          placeId: { type: 'string', description: 'Place document id when type=document' },
          latitude: { type: 'number' },
          longitude: { type: 'number' },
          address: { type: 'string' },
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
          body: { type: 'string', minLength: 2 },
          status: { type: 'string', enum: ['DRAFT', 'PUBLISHED'] },
          categoryId: { type: 'string', nullable: true },
          type: { type: 'string' },
          placeId: { type: 'string', nullable: true },
          latitude: { type: 'number', nullable: true },
          longitude: { type: 'number', nullable: true },
          address: { type: 'string', nullable: true },
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
    '/api/document': {
      get: {
        tags: ['document'],
        summary: 'List document (paginated)',
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'status', in: 'query', schema: { type: 'string' } },
          { name: 'categoryId', in: 'query', schema: { type: 'string' } },
          { name: 'type', in: 'query', schema: { type: 'string' } },
          { name: 'authorId', in: 'query', schema: { type: 'string' } },
          { name: 'placeId', in: 'query', schema: { type: 'string' } },
          { name: 'lat', in: 'query', schema: { type: 'number' }, description: 'Nearby filter (with lng, radiusKm)' },
          { name: 'lng', in: 'query', schema: { type: 'number' } },
          { name: 'radiusKm', in: 'query', schema: { type: 'number', default: 25 } },
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
  },
};
