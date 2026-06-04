import { message } from 'antd';
import { createContext, useCallback, useContext, useEffect, useState } from 'react';

import { fetchSettings, updateSettings, type SystemSettings } from '@/api/settings';

interface SettingsContextValue {
  settings: SystemSettings | null;
  loading: boolean;
  saving: boolean;
  toggleAutoApprove: (key: 'autoApproveDocuments' | 'autoApprovePlaces', checked: boolean) => Promise<void>;
}

const SettingsContext = createContext<SettingsContextValue | null>(null);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [settings, setSettings] = useState<SystemSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    try {
      const data = await fetchSettings();
      setSettings(data);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const toggleAutoApprove = async (key: 'autoApproveDocuments' | 'autoApprovePlaces', checked: boolean) => {
    if (!settings) return;
    setSaving(true);
    try {
      const updated = await updateSettings({ [key]: checked });
      setSettings(updated);
      message.success('Đã lưu cài đặt');
    } catch {
      message.error('Lưu thất bại');
    } finally {
      setSaving(false);
    }
  };

  return (
    <SettingsContext.Provider value={{ settings, loading, saving, toggleAutoApprove }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error('useSettings must be used within SettingsProvider');
  return ctx;
}
