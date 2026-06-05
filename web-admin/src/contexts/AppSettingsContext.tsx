import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

type Theme = 'light' | 'dark';
type Language = 'vi' | 'en';

interface AppSettingsContextValue {
  theme: Theme;
  language: Language;
  setTheme: (t: Theme) => void;
  setLanguage: (l: Language) => void;
}

const AppSettingsContext = createContext<AppSettingsContextValue | null>(null);

export function AppSettingsProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(
    () => (localStorage.getItem('admin_theme') as Theme) ?? 'light',
  );
  const [language, setLanguageState] = useState<Language>(
    () => (localStorage.getItem('admin_language') as Language) ?? 'vi',
  );

  const setTheme = (t: Theme) => {
    setThemeState(t);
    localStorage.setItem('admin_theme', t);
  };

  const setLanguage = (l: Language) => {
    setLanguageState(l);
    localStorage.setItem('admin_language', l);
  };

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  return (
    <AppSettingsContext.Provider value={{ theme, language, setTheme, setLanguage }}>
      {children}
    </AppSettingsContext.Provider>
  );
}

export function useAppSettings() {
  const ctx = useContext(AppSettingsContext);
  if (!ctx) throw new Error('useAppSettings must be used within AppSettingsProvider');
  return ctx;
}