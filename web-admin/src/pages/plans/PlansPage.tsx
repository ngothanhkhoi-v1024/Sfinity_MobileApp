import { CrownOutlined, SaveOutlined } from '@ant-design/icons';
import {
  Button,
  Card,
  Col,
  Divider,
  Form,
  Input,
  InputNumber,
  Row,
  Switch,
  Typography,
  message,
} from 'antd';
import { useCallback, useEffect, useState } from 'react';

import {
  fetchPlanSettings,
  updatePlanSettings,
  type FreeLimitsConfig,
  type PlanSettings,
} from '@/api/plans';
import { formatVnd } from '@/api/subscriptions';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

const { Title, Text } = Typography;

interface FormValues {
  pro: {
    name: string;
    monthlyPrice: number;
    yearlyPrice: number;
    enabled: boolean;
  };
  freeLimits: FreeLimitsConfig;
}

function toFormValues(settings: PlanSettings): FormValues {
  const pro = settings.plans.pro ?? {
    id: 'pro',
    name: 'VIP Pro',
    nameVi: 'VIP Pro',
    monthlyPrice: 49000,
    yearlyPrice: 399000,
    enabled: true,
  };
  return {
    pro: {
      name: pro.nameVi?.trim() || pro.name,
      monthlyPrice: pro.monthlyPrice,
      yearlyPrice: pro.yearlyPrice,
      enabled: pro.enabled,
    },
    freeLimits: { ...settings.freeLimits },
  };
}

export function PlansPage() {
  const [form] = Form.useForm<FormValues>();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const settings = await fetchPlanSettings();
      form.setFieldsValue(toFormValues(settings));
    } catch {
      message.error('Không tải được cấu hình gói');
    } finally {
      setLoading(false);
    }
  }, [form]);

  useEffect(() => {
    load();
  }, [load]);

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await updatePlanSettings({
        plans: {
          pro: {
            name: values.pro.name,
            nameVi: values.pro.name,
            monthlyPrice: values.pro.monthlyPrice,
            yearlyPrice: values.pro.yearlyPrice,
            enabled: values.pro.enabled,
          },
        },
        freeLimits: values.freeLimits,
      });
      message.success('Đã lưu cấu hình gói');
      await load();
    } catch {
      message.error('Không lưu được cấu hình');
    } finally {
      setSaving(false);
    }
  };

  const monthlyPrice = Form.useWatch(['pro', 'monthlyPrice'], form);
  const yearlyPrice = Form.useWatch(['pro', 'yearlyPrice'], form);

  return (
    <PageShell>
      <PageHeader
        title="Cấu hình gói VIP"
        description="Điều chỉnh giá gói VIP và hạn mức tài khoản thường"
        extra={
          <Button type="primary" icon={<SaveOutlined />} loading={saving} onClick={handleSave}>
            Lưu thay đổi
          </Button>
        }
      />

      <Form form={form} layout="vertical" disabled={loading}>
        <Row gutter={[20, 20]}>
          <Col xs={24} lg={14}>
            <Card className="admin-page-card" loading={loading} styles={{ body: { padding: '24px 28px' } }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
                <div style={{
                  width: 40, height: 40, borderRadius: 10,
                  background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <CrownOutlined style={{ color: '#fff', fontSize: 18 }} />
                </div>
                <div>
                  <Title level={5} style={{ margin: 0 }}>Gói VIP Pro</Title>
                  <Text type="secondary" style={{ fontSize: 13 }}>Giá hiển thị trên app và dùng khi thanh toán</Text>
                </div>
              </div>

              <Form.Item name={['pro', 'name']} label="Tên gói" rules={[{ required: true }]}>
                <Input placeholder="VD: VIP Pro" />
              </Form.Item>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name={['pro', 'monthlyPrice']}
                    label="Giá tháng (VND)"
                    rules={[{ required: true, type: 'number', min: 0 }]}
                  >
                    <InputNumber style={{ width: '100%' }} min={0} step={1000} formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name={['pro', 'yearlyPrice']}
                    label="Giá năm (VND)"
                    rules={[{ required: true, type: 'number', min: 0 }]}
                  >
                    <InputNumber style={{ width: '100%' }} min={0} step={10000} formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')} />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item name={['pro', 'enabled']} label="Bật gói" valuePropName="checked">
                <Switch checkedChildren="Đang bán" unCheckedChildren="Tắt" />
              </Form.Item>

              {(monthlyPrice != null || yearlyPrice != null) && (
                <Text type="secondary" style={{ fontSize: 13 }}>
                  Xem trước: {formatVnd(monthlyPrice ?? 0)}/tháng · {formatVnd(yearlyPrice ?? 0)}/năm
                </Text>
              )}
            </Card>
          </Col>

          <Col xs={24} lg={10}>
            <Card className="admin-page-card" loading={loading} styles={{ body: { padding: '24px 28px' } }}>
              <Title level={5} style={{ marginTop: 0 }}>Hạn mức tài khoản thường</Title>
              <Text type="secondary" style={{ display: 'block', marginBottom: 16, fontSize: 13 }}>
                Giới hạn cho user chưa nâng cấp VIP. VIP không bị giới hạn.
              </Text>

              <Form.Item
                name={['freeLimits', 'documentDownloads']}
                label="Lượt tải tài liệu"
                rules={[{ required: true, type: 'number', min: 0 }]}
              >
                <InputNumber style={{ width: '100%' }} min={0} />
              </Form.Item>

              <Form.Item
                name={['freeLimits', 'placesCreated']}
                label="Lượt đăng địa điểm"
                rules={[{ required: true, type: 'number', min: 0 }]}
              >
                <InputNumber style={{ width: '100%' }} min={0} />
              </Form.Item>

              <Form.Item
                name={['freeLimits', 'friends']}
                label="Số bạn bè tối đa"
                rules={[{ required: true, type: 'number', min: 0 }]}
              >
                <InputNumber style={{ width: '100%' }} min={0} />
              </Form.Item>

              <Divider style={{ margin: '12px 0' }} />

              <Form.Item
                name={['freeLimits', 'canCreateGroup']}
                label="Cho phép tạo nhóm"
                valuePropName="checked"
                extra="Mặc định tắt — chỉ VIP mới tạo nhóm"
              >
                <Switch checkedChildren="Có" unCheckedChildren="Không" />
              </Form.Item>
            </Card>
          </Col>
        </Row>
      </Form>
    </PageShell>
  );
}
