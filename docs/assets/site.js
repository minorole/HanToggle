(() => {
  "use strict";

  const languages = ["zh-Hans", "zh-Hant", "en"];
  const defaultLanguage = "zh-Hans";
  const storageKey = "hantoggle-language";

  const translations = {
    "zh-Hans": {
      title: "HanToggle - macOS 中文简繁转换",
      description: "HanToggle 是一款轻量的 macOS 菜单栏工具。选中一段中文，按下全局快捷键，即可在简体和繁体之间转换。",
      ogDescription: "在大多数 Mac 应用中选中文字，按下快捷键，转换结果会直接替换原文。",
      skipLink: "跳到内容",
      primaryNavigation: "主导航",
      homeLabel: "HanToggle 主页",
      siteLinks: "网站链接",
      navSetup: "开始使用",
      navPrivacy: "隐私",
      download: "下载",
      heroLede: "一个快捷键，简繁互转。",
      heroText: "在大多数 Mac 应用中选中文字，转换结果会直接替换原文。",
      primaryActions: "主要操作",
      heroDownloadLabel: "下载 HanToggle 0.1.0 Mac 版（DMG）",
      downloadForMac: "下载 Mac 版",
      workflowPreview: "HanToggle 操作预览",
      workflowAlt: "HanToggle 操作预览：按下 Control + Option + H，转换选中的中文。",
      essentials: "HanToggle 要点",
      keyBenefits: "主要特点",
      twoWayTitle: "双向转换",
      twoWayText: "再按一次，就能转换回来。",
      clipboardTitle: "保留剪贴板内容",
      clipboardText: "转换完成后恢复原来的内容。",
      compatibilityText: "支持配备 Apple 芯片或 Intel 处理器的 Mac。",
      setupTitle: "开始使用",
      installTitle: "安装",
      installText: "将 HanToggle 拖入“应用程序”。",
      allowTitle: "授权",
      allowText: "启用 HanToggle 的辅助功能权限。",
      toggleTitle: "转换文字",
      toggleText: "按下你设置的快捷键。",
      privateEyebrow: "隐私",
      privacyTitle: "文字只留在你的 Mac 上。",
      privacyText: "不收集使用数据，不上传或记录你的文字。",
      openSource: "开源",
      downloadForMacTitle: "下载 Mac 版",
      licenseText: "采用 MIT 许可证，源代码公开在 GitHub。",
      supportNote: "联系支持时，请勿发送敏感文字、剪贴板内容、账号密码、访问令牌、密钥或个人信息。",
      support: "联系支持",
      nextLanguage: "繁體",
      toggleLabel: "切换到繁體中文",
      languageToggleTitle: "切换到繁體中文"
    },
    "zh-Hant": {
      title: "HanToggle - macOS 中文簡繁轉換",
      description: "HanToggle 是一款輕量的 macOS 選單列工具。選取一段中文，按下全域快速鍵，即可在簡體和繁體之間轉換。",
      ogDescription: "在大多數 Mac 應用程式中選取文字，按下快速鍵，轉換結果會直接取代原文。",
      skipLink: "跳到內容",
      primaryNavigation: "主導覽",
      homeLabel: "HanToggle 首頁",
      siteLinks: "網站連結",
      navSetup: "開始使用",
      navPrivacy: "隱私",
      download: "下載",
      heroLede: "一個快速鍵，簡繁互轉。",
      heroText: "在大多數 Mac 應用程式中選取文字，轉換結果會直接取代原文。",
      primaryActions: "主要操作",
      heroDownloadLabel: "下載 HanToggle 0.1.0 Mac 版（DMG）",
      downloadForMac: "下載 Mac 版",
      workflowPreview: "HanToggle 操作預覽",
      workflowAlt: "HanToggle 操作預覽：按下 Control + Option + H，轉換選取的中文。",
      essentials: "HanToggle 重點",
      keyBenefits: "主要特點",
      twoWayTitle: "雙向轉換",
      twoWayText: "再按一次，就能轉換回來。",
      clipboardTitle: "保留剪貼簿內容",
      clipboardText: "轉換完成後還原原來的內容。",
      compatibilityText: "支援配備 Apple 晶片或 Intel 處理器的 Mac。",
      setupTitle: "開始使用",
      installTitle: "安裝",
      installText: "將 HanToggle 拖入「應用程式」。",
      allowTitle: "授權",
      allowText: "啟用 HanToggle 的輔助使用權限。",
      toggleTitle: "轉換文字",
      toggleText: "按下你設定的快速鍵。",
      privateEyebrow: "隱私",
      privacyTitle: "文字只留在你的 Mac 上。",
      privacyText: "不收集使用資料，也不會上傳或記錄你的文字。",
      openSource: "開源",
      downloadForMacTitle: "下載 Mac 版",
      licenseText: "採用 MIT 授權，原始碼公開在 GitHub。",
      supportNote: "聯絡支援時，請勿傳送敏感文字、剪貼簿內容、帳號密碼、存取權杖、金鑰或個人資料。",
      support: "聯絡支援",
      nextLanguage: "EN",
      toggleLabel: "切換到英文",
      languageToggleTitle: "切換到英文"
    },
    en: {
      title: "HanToggle - Chinese script conversion for macOS",
      description: "HanToggle is a lightweight macOS menu-bar utility for toggling selected Chinese text between Simplified and Traditional with a global hotkey.",
      ogDescription: "Select Chinese text in most Mac apps. Press one hotkey. Convert between Simplified and Traditional locally.",
      skipLink: "Skip to content",
      primaryNavigation: "Primary navigation",
      homeLabel: "HanToggle home",
      siteLinks: "Site links",
      navSetup: "Setup",
      navPrivacy: "Privacy",
      download: "Download",
      heroLede: "One shortcut to switch Chinese scripts.",
      heroText: "Select Chinese text in most Mac apps. Convert it in place.",
      primaryActions: "Primary actions",
      heroDownloadLabel: "Download HanToggle 0.1.0 DMG for Mac",
      downloadForMac: "Download for Mac",
      workflowPreview: "HanToggle workflow preview",
      workflowAlt: "HanToggle workflow preview showing selected Chinese text toggled with Control Option H.",
      essentials: "HanToggle essentials",
      keyBenefits: "Key benefits",
      twoWayTitle: "Two-way toggle",
      twoWayText: "Press again to switch back.",
      clipboardTitle: "Clipboard safe",
      clipboardText: "Restored after conversion.",
      compatibilityText: "Apple Silicon and Intel.",
      setupTitle: "Setup.",
      installTitle: "Install",
      installText: "Drag HanToggle to Applications.",
      allowTitle: "Allow",
      allowText: "Enable Accessibility.",
      toggleTitle: "Toggle text",
      toggleText: "Use your hotkey.",
      privateEyebrow: "Private",
      privacyTitle: "Your text stays on your Mac.",
      privacyText: "No analytics, telemetry, server conversion, or text logging.",
      openSource: "Open source",
      downloadForMacTitle: "Download for Mac.",
      licenseText: "MIT licensed. Source on GitHub.",
      supportNote: "Do not send private text, clipboard contents, credentials, or personal data.",
      support: "Support",
      nextLanguage: "简体",
      toggleLabel: "Switch language. Current: English. Next: Simplified Chinese.",
      languageToggleTitle: "Switch to Simplified Chinese"
    }
  };

  const languageToggle = document.querySelector("[data-language-toggle]");
  const description = document.querySelector('meta[name="description"]');
  const ogDescription = document.querySelector('meta[property="og:description"]');

  const readStoredLanguage = () => {
    try {
      const storedLanguage = window.localStorage.getItem(storageKey);
      return languages.includes(storedLanguage) ? storedLanguage : defaultLanguage;
    } catch {
      return defaultLanguage;
    }
  };

  const storeLanguage = (language) => {
    try {
      window.localStorage.setItem(storageKey, language);
    } catch {
      // Language switching still works when storage is unavailable.
    }
  };

  const applyLanguage = (language) => {
    const copy = translations[language];

    document.documentElement.lang = language;
    document.title = copy.title;
    description.content = copy.description;
    ogDescription.content = copy.ogDescription;

    document.querySelectorAll("[data-i18n]").forEach((element) => {
      element.textContent = copy[element.dataset.i18n];
    });

    document.querySelectorAll("[data-i18n-aria-label]").forEach((element) => {
      element.setAttribute("aria-label", copy[element.dataset.i18nAriaLabel]);
    });

    document.querySelectorAll("[data-i18n-alt]").forEach((element) => {
      element.setAttribute("alt", copy[element.dataset.i18nAlt]);
    });

    languageToggle.textContent = copy.nextLanguage;
    languageToggle.setAttribute("aria-label", copy.toggleLabel);
    languageToggle.title = copy.languageToggleTitle;
    languageToggle.dataset.language = language;
  };

  let currentLanguage = readStoredLanguage();
  applyLanguage(currentLanguage);

  languageToggle.addEventListener("click", () => {
    const currentIndex = languages.indexOf(currentLanguage);
    currentLanguage = languages[(currentIndex + 1) % languages.length];
    applyLanguage(currentLanguage);
    storeLanguage(currentLanguage);
  });
})();
