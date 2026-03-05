/**
 * Liftly マーケティングサイト - 日英切り替え
 * - URL パラメータ: ?lang=ja | ?lang=en（未指定時は ja）。App Store の言語別プライバシーURL にそのまま利用可能。
 * - 言語別リンク: translations.*.urls の appStore / contactForm / privacyPolicy を変更すると、data-i18n-href のリンクが切り替わります。
 */
(function () {
  'use strict';

  var translations = {
    ja: {
      'meta.title': 'Liftly - シンプルで続く、筋トレ記録アプリ',
      'meta.description': 'Liftly - シンプルで美しい筋トレ記録アプリ。トレーニングログ、種目別成長グラフ、体重管理を一つに。',
      'nav.features': '機能',
      'nav.howto': '使い方',
      'nav.privacy': 'プライバシー',
      'nav.contact': 'お問い合わせ',
      'hero.badge': '筋トレ記録アプリ',
      'hero.tagline': 'シンプルで美しい。続けたくなるトレーニングログ。\n重量・回数・種目別の成長を、一つにまとめて。',
      'hero.videoTitle': 'Liftlyアプリのプロモーション動画',
      'hero.watchYoutube': 'YouTube で見る',
      'hero.appStore': 'App Store でダウンロード',
      'features.title': 'トレーニングを、もっとシンプルに',
      'features.desc': 'Liftlyは、記録に悩まされず本気のトレーニングに集中できるアプリです。',
      'features.f1.title': '直感的な記録',
      'features.f1.desc': '種目を選び、重量と回数を入力するだけ。前回の記録をワンタップで再現できるので、セット間の操作は最小限です。',
      'features.f2.title': '種目別の成長グラフ',
      'features.f2.desc': '重量・回数・ボリュームの推移をグラフで確認。1M〜5Yの期間で、あなたの成長を視覚的に把握できます。',
      'features.f3.title': 'セット間タイマー',
      'features.f3.desc': '休憩時間を計測。バックグラウンドでも動作するので、スマホを置いたまま次のセットに備えられます。',
      'features.f4.title': '体重管理',
      'features.f4.desc': '体重の推移を記録し、月間の変化を確認。トレーニング頻度と体重の関係をインサイトで把握できます。',
      'features.f5.title': 'バックアップ・復元',
      'features.f5.desc': 'JSON/CSV形式でエクスポート・インポート可能。データは端末内に保存され、あなたがコントロールできます。',
      'features.f6.title': 'カスタマイズ',
      'features.f6.desc': 'テーマや単位（kg/lb）、言語（日本語/English）を切り替え。あなた好みの環境で続けられます。',
      'howto.title': 'はじめ方',
      'howto.desc': '初回起動から最初のワークアウトまで、3ステップでスタート。',
      'howto.s1.title': 'アプリを起動し、トレーニング開始',
      'howto.s1.desc': 'ホーム画面の「トレーニング開始」をタップ。種目を追加して、重量・回数を入力します。セットを追加するときは「セット追加」ボタンで簡単に記録できます。',
      'howto.s2.title': '記録完了でセッションを保存',
      'howto.s2.desc': 'トレーニングが終わったら「記録完了」をタップ。その日のワークアウトがカレンダーと履歴に保存されます。後から編集・削除も可能です。',
      'howto.s3.title': '成長をグラフで確認',
      'howto.s3.desc': '種目一覧から任意の種目をタップすると、成長グラフを表示。重量・回数・ボリュームの推移を期間（1M〜5Y）で切り替えて確認できます。',
      'privacy.title': 'プライバシーポリシー',
      'privacy.p1': '本アプリは個人情報を収集しません。トレーニングデータは端末内にのみ保存され、外部に送信されることはありません。',
      'privacy.p2': 'アプリ内課金、広告表示に関わる処理について、各サービス提供者のポリシーが適用されます。\n詳しくはアプリ内の利用規約・プライバシーポリシーをご確認ください。',
      'contact.title': 'お問い合わせ',
      'contact.desc': 'ご質問・ご要望は以下のフォームよりお送りください。',
      'contact.btn': 'お問い合わせフォームを開く',
      'footer.features': '機能',
      'footer.howto': '使い方',
      'footer.privacy': 'プライバシー',
      'footer.contact': 'お問い合わせ',
      'footer.appAds': 'app-ads.txt',
      'footer.copyright': '© Liftly - Simple Fitness Log',
      'lang.ja': '日本語',
      'lang.en': 'English',
      urls: {
        appStore: 'https://apps.apple.com/app/liftly-simple-workout-log/id6757798075',
        contactForm: 'https://forms.gle/kwtwF2FkEDE12ZcX8',
        privacyPolicy: null,
        youtubeShort: 'https://youtube.com/shorts/HWuYU6D3kqw?feature=share'
      }
    },
    en: {
      'meta.title': 'Liftly - Simple Workout Log',
      'meta.description': 'Liftly - A simple, beautiful workout logger. Training log, progress by exercise, and weight tracking in one app.',
      'nav.features': 'Features',
      'nav.howto': 'How to',
      'nav.privacy': 'Privacy',
      'nav.contact': 'Contact',
      'hero.badge': 'Workout Log App',
      'hero.tagline': 'Simple and clear. A training log you’ll want to keep.\nTrack weight, reps, and progress by exercise in one place.',
      'hero.videoTitle': 'Liftly app promotion video',
      'hero.watchYoutube': 'Watch on YouTube',
      'hero.appStore': 'Download on the App Store',
      'features.title': 'Training, made simpler',
      'features.desc': 'Liftly lets you focus on your workout instead of wrestling with your log.',
      'features.f1.title': 'Intuitive logging',
      'features.f1.desc': 'Pick an exercise, enter weight and reps. One tap to repeat your last set, so you spend less time on your phone between sets.',
      'features.f2.title': 'Progress by exercise',
      'features.f2.desc': 'View trends for weight, reps, and volume in graphs. Switch between 1M and 5Y to see how you’re growing.',
      'features.f3.title': 'Rest timer',
      'features.f3.desc': 'Time your rest between sets. Runs in the background so you can put your phone down until the next set.',
      'features.f4.title': 'Weight tracking',
      'features.f4.desc': 'Log your weight and see monthly changes. See how training frequency and weight relate over time.',
      'features.f5.title': 'Backup & restore',
      'features.f5.desc': 'Export and import as JSON or CSV. Data stays on your device and under your control.',
      'features.f6.title': 'Customization',
      'features.f6.desc': 'Switch theme, units (kg/lb), and language (Japanese/English) to match your preference.',
      'howto.title': 'Getting started',
      'howto.desc': 'From first launch to your first workout in three steps.',
      'howto.s1.title': 'Start a workout',
      'howto.s1.desc': 'Tap “Start workout” on the home screen. Add exercises and enter weight and reps. Use “Add set” to log each set quickly.',
      'howto.s2.title': 'Save your session',
      'howto.s2.desc': 'When you’re done, tap “Finish”. Your workout is saved to the calendar and history. You can edit or delete it later.',
      'howto.s3.title': 'Check your progress',
      'howto.s3.desc': 'Tap any exercise in the list to open its progress graph. Switch between 1M and 5Y to view weight, reps, and volume over time.',
      'privacy.title': 'Privacy Policy',
      'privacy.p1': 'This app does not collect personal information. Training data is stored only on your device and is not sent to external servers.',
      'privacy.p2': 'In-app purchases and ads are subject to the respective service providers’ policies.\nSee the in-app terms and privacy policy for details.',
      'contact.title': 'Contact',
      'contact.desc': 'Send questions or feedback using the form below.',
      'contact.btn': 'Open contact form',
      'footer.features': 'Features',
      'footer.howto': 'How to',
      'footer.privacy': 'Privacy',
      'footer.contact': 'Contact',
      'footer.appAds': 'app-ads.txt',
      'footer.copyright': '© Liftly - Simple Fitness Log',
      'lang.ja': '日本語',
      'lang.en': 'English',
      urls: {
        appStore: 'https://apps.apple.com/app/liftly-simple-workout-log/id6757798075',
        contactForm: 'https://forms.gle/4xBiNdntNHTSyRWc6',
        privacyPolicy: null,
        youtubeShort: 'https://youtube.com/shorts/HWuYU6D3kqw?feature=share'
      }
    }
  };

  var supportedLangs = ['ja', 'en'];
  var defaultLang = 'ja';

  function getLangFromUrl() {
    var params = new URLSearchParams(window.location.search);
    var lang = (params.get('lang') || '').toLowerCase();
    return supportedLangs.indexOf(lang) >= 0 ? lang : defaultLang;
  }

  function getLangUrl(lang) {
    var url = new URL(window.location.href);
    url.searchParams.set('lang', lang);
    return url.pathname + url.search;
  }

  function setMeta(lang) {
    var t = translations[lang];
    document.title = t['meta.title'];
    var metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.setAttribute('content', t['meta.description']);
  }

  function setDocumentLang(lang) {
    document.documentElement.lang = lang;
  }

  function escapeHtml(s) {
    var div = document.createElement('div');
    div.textContent = s;
    return div.innerHTML;
  }

  function applyText(lang) {
    var t = translations[lang];
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      var val = t[key];
      if (val == null) return;
      if (val.indexOf('\n') >= 0) {
        el.innerHTML = val.split('\n').map(escapeHtml).join('<br>');
      } else {
        el.textContent = val;
      }
    });
  }

  function applyUrls(lang) {
    var t = translations[lang];
    if (!t.urls) return;
    document.querySelectorAll('[data-i18n-href]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-href');
      var val = t.urls[key];
      if (val) el.setAttribute('href', val);
    });
  }

  function applyVideoTitle(lang) {
    var t = translations[lang];
    var iframe = document.querySelector('.hero-video-wrap .hero-video[title]');
    if (iframe && t['hero.videoTitle']) iframe.setAttribute('title', t['hero.videoTitle']);
  }

  function updateLangSwitcher(lang) {
    document.querySelectorAll('[data-lang-link]').forEach(function (el) {
      var linkLang = el.getAttribute('data-lang-link');
      el.setAttribute('href', getLangUrl(linkLang));
      el.classList.toggle('is-active', linkLang === lang);
      el.setAttribute('aria-current', linkLang === lang ? 'true' : 'false');
    });
  }

  function applyLang(lang) {
    setDocumentLang(lang);
    setMeta(lang);
    applyText(lang);
    applyUrls(lang);
    applyVideoTitle(lang);
    updateLangSwitcher(lang);
  }

  function init() {
    var lang = getLangFromUrl();
    applyLang(lang);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
