import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { CreateGroupDto, UpdateGroupDto } from '../dto/group.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const groupService = {
  /** Tạo nhóm mới */
  async createGroup(creatorId: string, dto: CreateGroupDto) {
    const db = getDb();
    const groupRef = db.collection('groups').doc();
    const groupId = groupRef.id;
    const now = new Date();

    const groupData = {
      id: groupId,
      name: dto.name,
      description: dto.description ?? null,
      avatarUrl: dto.avatarUrl ?? null,
      isPublic: dto.isPublic ?? false,
      creatorId,
      createdAt: now,
      updatedAt: now,
    };

    // Add group and first member (OWNER)
    await groupRef.set(groupData);

    const memberId = `${groupId}_${creatorId}`;
    const memberData = {
      id: memberId,
      groupId,
      userId: creatorId,
      role: 'OWNER',
      joinedAt: now,
    };
    await db.collection('group_members').doc(memberId).set(memberData);

    const userDoc = await db.collection('users').doc(creatorId).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    return {
      ...groupData,
      members: [
        {
          ...memberData,
          joinedAt: now,
          user: {
            id: creatorId,
            name: userData?.name ?? 'Unknown',
            avatar: userData?.avatar ?? null,
          },
        },
      ],
    };
  },

  /** Lấy thông tin chi tiết nhóm (phải là thành viên hoặc nhóm public) */
  async getGroup(groupId: string, userId: string) {
    const db = getDb();
    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw new HttpError(404, 'Nhóm không tồn tại.', 'Not Found');
    const groupData = groupDoc.data()!;

    // Get members
    const membersSnap = await db.collection('group_members')
      .where('groupId', '==', groupId)
      .get();
    
    const membersList = membersSnap.docs.map(d => d.data()!);

    const isMember = membersList.some((m) => m.userId === userId);
    if (!isMember && !groupData.isPublic) {
      throw new HttpError(403, 'Bạn không phải thành viên nhóm này.', 'Forbidden');
    }

    // Hydrate user info for all members
    const hydratedMembers = await Promise.all(
      membersList.map(async (m) => {
        const uDoc = await db.collection('users').doc(m.userId).get();
        const uData = uDoc.exists ? uDoc.data() : null;
        return {
          id: m.id,
          role: m.role,
          joinedAt: toDate(m.joinedAt),
          user: {
            id: m.userId,
            name: uData?.name ?? 'Unknown',
            avatar: uData?.avatar ?? null,
            email: uData?.email ?? '',
          },
        };
      })
    );

    // Sort by joinedAt asc
    hydratedMembers.sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime());

    // Hydrate creator
    const creatorDoc = await db.collection('users').doc(groupData.creatorId).get();
    const creatorData = creatorDoc.exists ? creatorDoc.data() : null;

    return {
      id: groupData.id,
      name: groupData.name,
      description: groupData.description,
      avatarUrl: groupData.avatarUrl,
      isPublic: groupData.isPublic,
      creatorId: groupData.creatorId,
      createdAt: toDate(groupData.createdAt),
      updatedAt: toDate(groupData.updatedAt),
      members: hydratedMembers,
      creator: {
        id: groupData.creatorId,
        name: creatorData?.name ?? 'Unknown',
        avatar: creatorData?.avatar ?? null,
      },
    };
  },

  /** Danh sách nhóm của user */
  async listUserGroups(userId: string) {
    const db = getDb();
    const membershipsSnap = await db.collection('group_members')
      .where('userId', '==', userId)
      .get();

    const memberships = membershipsSnap.docs.map(d => d.data()!);

    const groupsList = await Promise.all(
      memberships.map(async (m) => {
        const groupDoc = await db.collection('groups').doc(m.groupId).get();
        if (!groupDoc.exists) return null;
        const groupData = groupDoc.data()!;

        // Get members count
        const membersCountSnap = await db.collection('group_members')
          .where('groupId', '==', m.groupId)
          .get();

        const allGroupMembers = membersCountSnap.docs.map(d => d.data()!);
        
        // Take up to 5 members to hydrate
        const hydratedShortMembers = await Promise.all(
          allGroupMembers.slice(0, 5).map(async (gm) => {
            const uDoc = await db.collection('users').doc(gm.userId).get();
            const uData = uDoc.exists ? uDoc.data() : null;
            return {
              user: {
                id: gm.userId,
                name: uData?.name ?? 'Unknown',
                avatar: uData?.avatar ?? null,
              },
            };
          })
        );

        return {
          id: groupData.id,
          name: groupData.name,
          description: groupData.description,
          avatarUrl: groupData.avatarUrl,
          isPublic: groupData.isPublic,
          creatorId: groupData.creatorId,
          createdAt: toDate(groupData.createdAt),
          updatedAt: toDate(groupData.updatedAt),
          myRole: m.role,
          members: hydratedShortMembers,
          _count: {
            members: allGroupMembers.length,
          },
          joinedAt: toDate(m.joinedAt),
        };
      })
    );

    // Filter nulls and sort by joinedAt desc
    const result = groupsList.filter(g => g !== null) as any[];
    result.sort((a, b) => b.joinedAt.getTime() - a.joinedAt.getTime());

    return result;
  },

  /** Thêm thành viên vào nhóm */
  async addMember(groupId: string, actorId: string, targetUserId: string) {
    const db = getDb();
    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw new HttpError(404, 'Nhóm không tồn tại.', 'Not Found');
    const groupData = groupDoc.data()!;

    // Get current group members
    const membersSnap = await db.collection('group_members')
      .where('groupId', '==', groupId)
      .get();
    
    const membersList = membersSnap.docs.map(d => d.data()!);

    // Người thêm phải là thành viên nhóm
    const actor = membersList.find((m) => m.userId === actorId);
    if (!actor) throw new HttpError(403, 'Bạn không phải thành viên nhóm.', 'Forbidden');

    // Kiểm tra target đã là thành viên chưa
    const alreadyMember = membersList.some((m) => m.userId === targetUserId);
    if (alreadyMember) throw new HttpError(409, 'Người dùng đã là thành viên nhóm.', 'Conflict');

    // Nếu nhóm không public: target phải là bạn bè với actor
    if (!groupData.isPublic) {
      const key1 = `${actorId}_${targetUserId}`;
      const key2 = `${targetUserId}_${actorId}`;
      const [f1, f2] = await Promise.all([
        db.collection('friendships').doc(key1).get(),
        db.collection('friendships').doc(key2).get(),
      ]);

      const friendship = (f1.exists ? f1.data() : null) || (f2.exists ? f2.data() : null);

      if (!friendship || friendship.status !== 'ACCEPTED') {
        throw new HttpError(403, 'Chỉ có thể thêm bạn bè vào nhóm riêng tư.', 'Forbidden');
      }
    }

    // Kiểm tra user tồn tại
    const targetUserDoc = await db.collection('users').doc(targetUserId).get();
    if (!targetUserDoc.exists) throw new HttpError(404, 'Người dùng không tồn tại.', 'Not Found');
    const targetUserData = targetUserDoc.data()!;

    const memberId = `${groupId}_${targetUserId}`;
    const now = new Date();
    const memberData = {
      id: memberId,
      groupId,
      userId: targetUserId,
      role: 'MEMBER',
      joinedAt: now,
    };

    await db.collection('group_members').doc(memberId).set(memberData);

    return {
      ...memberData,
      user: {
        id: targetUserId,
        name: targetUserData.name ?? 'Unknown',
        avatar: targetUserData.avatar ?? null,
      },
    };
  },

  /** Xóa thành viên khỏi nhóm */
  async removeMember(groupId: string, actorId: string, targetUserId: string) {
    const db = getDb();
    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw new HttpError(404, 'Nhóm không tồn tại.', 'Not Found');

    const membersSnap = await db.collection('group_members')
      .where('groupId', '==', groupId)
      .get();
    
    const membersList = membersSnap.docs.map(d => d.data()!);

    const actor = membersList.find((m) => m.userId === actorId);
    if (!actor || (actor.role !== 'OWNER' && actor.role !== 'ADMIN')) {
      throw new HttpError(403, 'Chỉ OWNER hoặc ADMIN mới có thể xóa thành viên.', 'Forbidden');
    }

    const targetMember = membersList.find((m) => m.userId === targetUserId);
    if (!targetMember) throw new HttpError(404, 'Thành viên không tồn tại trong nhóm.', 'Not Found');
    if (targetMember.role === 'OWNER') throw new HttpError(403, 'Không thể xóa chủ nhóm.', 'Forbidden');

    await db.collection('group_members').doc(targetMember.id).delete();
    return { success: true };
  },

  /** Rời nhóm */
  async leaveGroup(groupId: string, userId: string) {
    const db = getDb();
    const memberId = `${groupId}_${userId}`;
    const memberDoc = await db.collection('group_members').doc(memberId).get();
    
    if (!memberDoc.exists) throw new HttpError(404, 'Bạn không phải thành viên nhóm.', 'Not Found');
    const memberData = memberDoc.data()!;

    if (memberData.role === 'OWNER') {
      throw new HttpError(403, 'Chủ nhóm không thể rời nhóm. Hãy xóa nhóm hoặc chuyển quyền chủ nhóm trước.', 'Forbidden');
    }

    await db.collection('group_members').doc(memberId).delete();
    return { success: true };
  },

  /** Cập nhật thông tin nhóm */
  async updateGroup(groupId: string, userId: string, dto: UpdateGroupDto) {
    const db = getDb();
    await this._requireOwnerOrAdmin(groupId, userId);

    const updateData: any = {
      updatedAt: new Date(),
    };
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.isPublic !== undefined) updateData.isPublic = dto.isPublic;
    if (dto.avatarUrl !== undefined) updateData.avatarUrl = dto.avatarUrl;

    await db.collection('groups').doc(groupId).update(updateData);
    
    const updatedDoc = await db.collection('groups').doc(groupId).get();
    return updatedDoc.data();
  },

  /** Xóa nhóm (chỉ OWNER) */
  async deleteGroup(groupId: string, userId: string) {
    const db = getDb();
    const memberId = `${groupId}_${userId}`;
    const memberDoc = await db.collection('group_members').doc(memberId).get();
    
    if (!memberDoc.exists || memberDoc.data()!.role !== 'OWNER') {
      throw new HttpError(403, 'Chỉ chủ nhóm mới có thể xóa nhóm.', 'Forbidden');
    }

    // Delete group members first
    const membersSnap = await db.collection('group_members')
      .where('groupId', '==', groupId)
      .get();
    
    const batch = db.batch();
    membersSnap.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Delete messages of the group to save storage if required
    const messagesSnap = await db.collection('groups').doc(groupId).collection('messages').get();
    messagesSnap.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Delete group document
    batch.delete(db.collection('groups').doc(groupId));
    
    await batch.commit();
    return { success: true };
  },

  /** Khám phá danh sách nhóm công khai mà user chưa tham gia */
  async discoverPublicGroups(userId: string) {
    const db = getDb();
    
    // Lấy các nhóm mà user đã tham gia để loại trừ
    const membershipsSnap = await db.collection('group_members')
      .where('userId', '==', userId)
      .get();
    const joinedGroupIds = new Set(membershipsSnap.docs.map(d => d.data().groupId));

    // Lấy tất cả nhóm công khai
    const publicGroupsSnap = await db.collection('groups')
      .where('isPublic', '==', true)
      .get();
    
    const publicGroups = publicGroupsSnap.docs.map(d => d.data()!);

    // Lọc nhóm chưa tham gia
    const discoverableGroups = publicGroups.filter(g => !joinedGroupIds.has(g.id));

    // Hydrate thông tin thành viên (giống listUserGroups)
    const result = await Promise.all(
      discoverableGroups.map(async (groupData) => {
        const membersCountSnap = await db.collection('group_members')
          .where('groupId', '==', groupData.id)
          .get();

        const allGroupMembers = membersCountSnap.docs.map(d => d.data()!);
        
        const hydratedShortMembers = await Promise.all(
          allGroupMembers.slice(0, 5).map(async (gm) => {
            const uDoc = await db.collection('users').doc(gm.userId).get();
            const uData = uDoc.exists ? uDoc.data() : null;
            return {
              user: {
                id: gm.userId,
                name: uData?.name ?? 'Unknown',
                avatar: uData?.avatar ?? null,
              },
            };
          })
        );

        return {
          id: groupData.id,
          name: groupData.name,
          description: groupData.description,
          avatarUrl: groupData.avatarUrl,
          isPublic: groupData.isPublic,
          creatorId: groupData.creatorId,
          createdAt: toDate(groupData.createdAt),
          updatedAt: toDate(groupData.updatedAt),
          members: hydratedShortMembers,
          _count: {
            members: allGroupMembers.length,
          },
        };
      })
    );

    // Sắp xếp theo ngày tạo mới nhất
    result.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return result;
  },

  /** Tham gia một nhóm công khai */
  async joinGroup(groupId: string, userId: string) {
    const db = getDb();
    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw new HttpError(404, 'Nhóm không tồn tại.', 'Not Found');
    const groupData = groupDoc.data()!;

    if (!groupData.isPublic) {
      throw new HttpError(403, 'Không thể tự ý tham gia nhóm riêng tư.', 'Forbidden');
    }

    const memberId = `${groupId}_${userId}`;
    const memberDoc = await db.collection('group_members').doc(memberId).get();
    if (memberDoc.exists) {
      throw new HttpError(409, 'Bạn đã là thành viên của nhóm này.', 'Conflict');
    }

    const now = new Date();
    const memberData = {
      id: memberId,
      groupId,
      userId,
      role: 'MEMBER',
      joinedAt: now,
    };

    await db.collection('group_members').doc(memberId).set(memberData);

    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    return {
      ...memberData,
      user: {
        id: userId,
        name: userData?.name ?? 'Unknown',
        avatar: userData?.avatar ?? null,
      },
    };
  },

  /** Helper: kiểm tra OWNER hoặc ADMIN */
  async _requireOwnerOrAdmin(groupId: string, userId: string) {
    const db = getDb();
    const memberId = `${groupId}_${userId}`;
    const memberDoc = await db.collection('group_members').doc(memberId).get();

    if (!memberDoc.exists) {
      throw new HttpError(403, 'Chỉ OWNER hoặc ADMIN mới có quyền thực hiện thao tác này.', 'Forbidden');
    }

    const memberData = memberDoc.data()!;
    if (memberData.role !== 'OWNER' && memberData.role !== 'ADMIN') {
      throw new HttpError(403, 'Chỉ OWNER hoặc ADMIN mới có quyền thực hiện thao tác này.', 'Forbidden');
    }
    return memberData;
  },

  /** Mời thành viên vào nhóm */
  async inviteMember(groupId: string, inviterId: string, inviteeId: string) {
    const db = getDb();
    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw new HttpError(404, 'Nhóm không tồn tại.', 'Not Found');
    const groupData = groupDoc.data()!;

    // Kiểm tra người mời phải là thành viên
    const membersSnap = await db.collection('group_members')
      .where('groupId', '==', groupId)
      .get();
    const membersList = membersSnap.docs.map(d => d.data()!);
    const isMember = membersList.some(m => m.userId === inviterId);
    if (!isMember) throw new HttpError(403, 'Bạn không phải thành viên nhóm.', 'Forbidden');

    // Kiểm tra người được mời đã là thành viên chưa
    const alreadyMember = membersList.some(m => m.userId === inviteeId);
    if (alreadyMember) throw new HttpError(409, 'Người dùng đã là thành viên nhóm.', 'Conflict');

    // Kiểm tra xem đã có lời mời PENDING nào chưa
    const inviteId = `${groupId}_${inviteeId}`;
    const inviteDoc = await db.collection('group_invitations').doc(inviteId).get();
    if (inviteDoc.exists) {
      const currentInvite = inviteDoc.data()!;
      if (currentInvite.status === 'PENDING') {
        throw new HttpError(409, 'Lời mời đang ở trạng thái chờ phản hồi.', 'Conflict');
      }
    }

    // Lấy thông tin người mời
    const inviterUserDoc = await db.collection('users').doc(inviterId).get();
    const inviterUserData = inviterUserDoc.exists ? inviterUserDoc.data() : null;

    // Lấy thông tin người được mời
    const inviteeUserDoc = await db.collection('users').doc(inviteeId).get();
    if (!inviteeUserDoc.exists) throw new HttpError(404, 'Người dùng được mời không tồn tại.', 'Not Found');

    const invitationData = {
      id: inviteId,
      groupId,
      groupName: groupData.name,
      groupAvatarUrl: groupData.avatarUrl ?? null,
      inviterId,
      inviterName: inviterUserData?.name ?? 'Unknown',
      inviteeId,
      status: 'PENDING',
      createdAt: new Date(),
    };

    await db.collection('group_invitations').doc(inviteId).set(invitationData);
    
    // Gửi thông báo đến người nhận
    await db.collection('notifications').add({
      userId: inviteeId,
      title: 'Lời mời vào nhóm học tập',
      body: `${inviterUserData?.name ?? 'Một người dùng'} đã mời bạn tham gia nhóm học tập "${groupData.name}".`,
      read: false,
      createdAt: new Date(),
    });

    return invitationData;
  },

  /** Lấy danh sách lời mời đã nhận của user */
  async getReceivedInvitations(userId: string) {
    const db = getDb();
    const snapshot = await db.collection('group_invitations')
      .where('inviteeId', '==', userId)
      .where('status', '==', 'PENDING')
      .get();

    const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as any));
    // Sắp xếp theo ngày tạo desc
    list.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    return list.map(item => ({
      id: item.id,
      groupId: item.groupId,
      groupName: item.groupName,
      groupAvatarUrl: item.groupAvatarUrl,
      inviterId: item.inviterId,
      inviterName: item.inviterName,
      inviteeId: item.inviteeId,
      status: item.status,
      createdAt: toDate(item.createdAt),
    }));
  },

  /** Lấy danh sách lời mời đang chờ của một nhóm */
  async getGroupInvitations(groupId: string) {
    const db = getDb();
    const snapshot = await db.collection('group_invitations')
      .where('groupId', '==', groupId)
      .where('status', '==', 'PENDING')
      .get();

    return snapshot.docs.map(doc => doc.data());
  },

  /** Chấp nhận hoặc từ chối lời mời */
  async respondToInvitation(invitationId: string, userId: string, accept: boolean) {
    const db = getDb();
    const inviteRef = db.collection('group_invitations').doc(invitationId);
    const inviteDoc = await inviteRef.get();
    if (!inviteDoc.exists) throw new HttpError(404, 'Lời mời không tồn tại.', 'Not Found');
    const inviteData = inviteDoc.data()!;

    if (inviteData.inviteeId !== userId) {
      throw new HttpError(403, 'Bạn không thể phản hồi lời mời của người khác.', 'Forbidden');
    }

    if (inviteData.status !== 'PENDING') {
      throw new HttpError(400, 'Lời mời đã được xử lý trước đó.', 'Bad Request');
    }

    if (accept) {
      // Cập nhật trạng thái lời mời là ACCEPTED
      await inviteRef.update({ status: 'ACCEPTED' });

      // Thêm thành viên vào nhóm
      const groupId = inviteData.groupId;
      const memberId = `${groupId}_${userId}`;
      const memberDoc = await db.collection('group_members').doc(memberId).get();
      if (!memberDoc.exists) {
        const now = new Date();
        const memberData = {
          id: memberId,
          groupId,
          userId,
          role: 'MEMBER',
          joinedAt: now,
        };
        await db.collection('group_members').doc(memberId).set(memberData);
      }
    } else {
      // Từ chối lời mời
      await inviteRef.update({ status: 'DECLINED' });
    }

    return { success: true };
  },
};
