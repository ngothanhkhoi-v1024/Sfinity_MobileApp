import nodemailer from 'nodemailer';
import { config } from '../lib/config';

let transporterPromise: Promise<nodemailer.Transporter> | null = null;

async function getTransporter(): Promise<nodemailer.Transporter> {
  if (config.smtpHost && config.smtpUser && config.smtpPass) {
    return nodemailer.createTransport({
      host: config.smtpHost,
      port: config.smtpPort,
      secure: config.smtpSecure,
      auth: {
        user: config.smtpUser,
        pass: config.smtpPass,
      },
    });
  }

  if (!transporterPromise) {
    transporterPromise = (async () => {
      console.log('Đang khởi tạo tài khoản Ethereal Mail thử nghiệm...');
      const testAccount = await nodemailer.createTestAccount();
      console.log(`Đã tạo tài khoản test Ethereal: User = ${testAccount.user}`);
      return nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
    })();
  }
  return transporterPromise;
}

export const mailService = {
  async sendEmail(to: string, subject: string, html: string) {
    try {
      const transporter = await getTransporter();
      const info = await transporter.sendMail({
        from: config.smtpFrom,
        to,
        subject,
        html,
      });

      console.log(`[Email] Đã gửi email tới: ${to} | Subject: ${subject}`);
      
      const previewUrl = nodemailer.getTestMessageUrl(info);
      if (previewUrl) {
        console.log(`[Email Preview Link] Xem nội dung email chi tiết tại: ${previewUrl}`);
      }
      return info;
    } catch (error) {
      console.error('[Email Error] Gửi email thất bại:', error);
      throw error;
    }
  },

  async sendVerificationEmail(to: string, name: string, token: string) {
    const verifyLink = `${config.apiBaseUrl}/auth/verify-email?email=${encodeURIComponent(to)}&token=${encodeURIComponent(token)}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #4f46e5; margin: 0; font-size: 26px;">Sfinity Mobile</h2>
          <p style="color: #6b7280; font-size: 14px; margin: 4px 0 0 0;">Xác minh địa chỉ Email của bạn</p>
        </div>
        <p>Xin chào <strong>${name}</strong>,</p>
        <p>Cảm ơn bạn đã đăng ký tài khoản tại Sfinity. Để kích hoạt tài khoản và tiếp tục đăng nhập, bạn vui lòng xác thực địa chỉ email bằng cách nhấn vào liên kết bên dưới:</p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${verifyLink}" style="background-color: #4f46e5; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.25);">Xác thực tài khoản</a>
        </div>
        <p style="font-size: 12px; color: #9ca3af; line-height: 1.5;">Nếu nút trên không hoạt động, bạn có thể copy và paste liên kết sau vào trình duyệt:<br>
        <a href="${verifyLink}" style="color: #4f46e5; word-break: break-all;">${verifyLink}</a></p>
        <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 24px 0;">
        <p style="font-size: 12px; color: #9ca3af; text-align: center; margin: 0;">© 2026 Sfinity. Tất cả các quyền được bảo lưu.</p>
      </div>
    `;
    await this.sendEmail(to, 'Sfinity - Kích hoạt tài khoản của bạn', html);
  },

  async sendForgotPasswordOtp(to: string, name: string, otpCode: string) {
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #e11d48; margin: 0; font-size: 26px;">Sfinity Mobile</h2>
          <p style="color: #6b7280; font-size: 14px; margin: 4px 0 0 0;">Yêu cầu Đặt lại Mật khẩu</p>
        </div>
        <p>Xin chào <strong>${name}</strong>,</p>
        <p>Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn tại Sfinity. Vui lòng sử dụng mã OTP gồm 6 chữ số bên dưới để tiến hành đặt mật khẩu mới:</p>
        <div style="text-align: center; margin: 32px 0;">
          <div style="background-color: #f3f4f6; color: #1f2937; padding: 18px 36px; border-radius: 12px; font-weight: 800; font-size: 32px; letter-spacing: 6px; display: inline-block; border: 1px dashed #d1d5db;">${otpCode}</div>
        </div>
        <p style="color: #6b7280; font-size: 14px; line-height: 1.5;">Lưu ý: Mã OTP này có thời hạn hiệu lực là <strong>15 phút</strong>. Tuyệt đối không chia sẻ mã này với bất kỳ ai để đảm bảo an toàn tài khoản.</p>
        <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 24px 0;">
        <p style="font-size: 12px; color: #9ca3af; text-align: center; margin: 0;">© 2026 Sfinity. Tất cả các quyền được bảo lưu.</p>
      </div>
    `;
    await this.sendEmail(to, 'Sfinity - Mã OTP khôi phục mật khẩu', html);
  }
};
