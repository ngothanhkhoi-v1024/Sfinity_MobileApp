import { Router } from 'express';

import { CreateGroupDto, UpdateGroupDto, AddGroupMemberDto } from '../dto/group.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { groupService } from '../services/group.service';

export const groupRouter = Router();

// Tất cả routes đều yêu cầu auth
groupRouter.use(jwtAuthMiddleware);

/** Danh sách nhóm của tôi */
groupRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json(await groupService.listUserGroups(req.user!.sub));
  }),
);

/** Tạo nhóm mới */
groupRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateGroupDto, req.body);
    res.status(201).json(await groupService.createGroup(req.user!.sub, dto));
  }),
);

/** Khám phá nhóm công khai */
groupRouter.get(
  '/discover',
  asyncHandler(async (req, res) => {
    res.json(await groupService.discoverPublicGroups(req.user!.sub));
  }),
);

/** Danh sách lời mời nhóm học tập đã nhận */
groupRouter.get(
  '/invitations/received',
  asyncHandler(async (req, res) => {
    res.json(await groupService.getReceivedInvitations(req.user!.sub));
  }),
);

/** Trả lời lời mời nhóm học tập */
groupRouter.post(
  '/invitations/:inviteId/respond',
  asyncHandler(async (req, res) => {
    const { accept } = req.body;
    res.json(await groupService.respondToInvitation(req.params.inviteId, req.user!.sub, accept === true));
  }),
);

/** Chi tiết nhóm */
groupRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await groupService.getGroup(req.params.id, req.user!.sub));
  }),
);

/** Cập nhật nhóm */
groupRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateGroupDto, req.body);
    res.json(await groupService.updateGroup(req.params.id, req.user!.sub, dto));
  }),
);

/** Xóa nhóm */
groupRouter.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await groupService.deleteGroup(req.params.id, req.user!.sub));
  }),
);

/** Thêm thành viên */
groupRouter.post(
  '/:id/members',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AddGroupMemberDto, req.body);
    res.status(201).json(await groupService.addMember(req.params.id, req.user!.sub, dto.userId));
  }),
);

/** Xóa thành viên */
groupRouter.delete(
  '/:id/members/:uid',
  asyncHandler(async (req, res) => {
    res.json(await groupService.removeMember(req.params.id, req.user!.sub, req.params.uid));
  }),
);

/** Phê duyệt yêu cầu tham gia */
groupRouter.post(
  '/:id/members/:uid/approve',
  asyncHandler(async (req, res) => {
    res.json(await groupService.approveMember(req.params.id, req.user!.sub, req.params.uid));
  }),
);

/** Rời nhóm */
groupRouter.post(
  '/:id/leave',
  asyncHandler(async (req, res) => {
    const { newOwnerId } = req.body;
    res.json(await groupService.leaveGroup(req.params.id, req.user!.sub, newOwnerId));
  }),
);

/** Tự gia nhập nhóm công khai */
groupRouter.post(
  '/:id/join',
  asyncHandler(async (req, res) => {
    res.status(201).json(await groupService.joinGroup(req.params.id, req.user!.sub));
  }),
);

/** Mời thành viên vào nhóm */
groupRouter.post(
  '/:id/invite',
  asyncHandler(async (req, res) => {
    const { userId } = req.body;
    res.json(await groupService.inviteMember(req.params.id, req.user!.sub, userId));
  }),
);

/** Xem danh sách lời mời đang chờ của nhóm */
groupRouter.get(
  '/:id/invitations',
  asyncHandler(async (req, res) => {
    res.json(await groupService.getGroupInvitations(req.params.id));
  }),
);
