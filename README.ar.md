[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> هذه ترجمة لـ [README الإنجليزي](./README.md). عند وجود أي تعارض، تُعدّ النسخة الإنجليزية هي المرجع الرسمي.

<div align="center">

# Rails Mermaid ERD

**أنشئ مخطط ERD تفاعليًا بصيغة Mermaid لتطبيق Rails الخاص بك في ملف HTML واحد مستقل.**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="عارض Rails Mermaid ERD يعرض خمسة نماذج مع مفاتيحها الأساسية والأجنبية مرتبطة بخطوط العلاقات." src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[صفحة العرض التوضيحي](https://koedame.github.io/rails-mermaid_erd/example.html) · [التثبيت](#التثبيت) · [الاستخدام](#الاستخدام) · [الإصدارات المدعومة](#الإصدارات-المدعومة) · [الإعداد](#الإعداد)

</div>

نفّذ الأمر `rails mermaid_erd` لتحصل على ملف HTML واحد مستقل يحتوي على مخطط قاعدة بيانات تطبيق Rails الخاص بك، دون الحاجة إلى حزم gem أو خدمات إضافية. تأتي Tailwind وMermaid وVue مضمَّنة داخله، لذا يمكن فتحه دون اتصال بالإنترنت وخلف وكيل (proxy) الشركة. اختر في المتصفح الجداول التي تريدها وصدِّرها بصيغة كود Mermaid أو SVG أو PNG؛ وللمشاركة يكفي إرسال ملف HTML أو وضعه على خادم ويب.

## أبرز الميزات

- **ملف واحد ولا شيء آخر للتثبيت.** الناتج ملف HTML واحد بحجم نحو 4 ميغابايت تتضمّن داخله Tailwind وMermaid وVue، فيُفتح دون اتصال وخلف وكيل الشركة.
- **ارسم ما تحتاجه فقط.** اختر النماذج، واعرض كل الأعمدة أو المفاتيح فقط أو لا شيء، وأضف التعليقات وتسميات العلاقات.
- **التصدير والمشاركة.** انسخ شيفرة Mermaid أو Markdown، ونزّل SVG أو PNG، أو انسخ رابطًا يستعيد عرضك.
- **دعم واسع لـ Rails.** يغطي CI إصدارات Rails من 5.2 إلى 8.1 مع Ruby من 2.7 إلى 4.0.
- **12 لغة.** تتبع الواجهة لغة المتصفح، بما في ذلك العربية المكتوبة من اليمين إلى اليسار.

## التثبيت

أضف هذا السطر إلى ملف Gemfile في تطبيقك:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

ثم نفّذ:

```bash
bundle install
```

أضف ما يلي إلى ملف Rakefile في تطبيقك **قبل** `Rails.application.load_tasks` (يتم تسجيل المهمة عند تحميل المهام، لذا فإن وضع `require` بعد ذلك السطر يجعل `rails mermaid_erd` غير معروف):

```ruby
require_relative "config/application"

begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end

Rails.application.load_tasks
```

## الاستخدام

تشغيل مهمة Rake المسماة `mermaid_erd` سيولّد الملف `<app_root>/mermaid_erd/index.html`.

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

افتح الملف المولَّد `<app_root>/mermaid_erd/index.html` مباشرةً في متصفحك.

لا يلزم إضافة هذا الملف إلى إدارة Git، لذا يمكنك استثناؤه عبر `.gitignore` عند الحاجة:

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` ملف HTML مكتفٍ بذاته. جميع التبعيات الأمامية (Tailwind وMermaid وVue) مضمَّنة فيه، لذا يعمل دون اتصال بالإنترنت وخلف وكلاء الشركات الصارمة — لا حاجة للوصول إلى أي CDN عند العرض. حجم الملف نحو 4 ميغابايت بسبب الحزم المدمجة.

إذا شاركت هذا الملف، أمكن استخدامه لمن لا تتوفر لديهم بيئة Ruby on Rails. كما يمكنك رفعه على خادم ويب ومشاركته عبر رابط موحّد.

يحتوي الملف المُنشأ على مخطط تطبيقك، بما في ذلك أسماء الجداول والأعمدة والتعليقات. شاركه أو استضفه فقط ضمن النطاق نفسه الذي تشارك فيه المخطط ذاته.

من الأنسب جداً أتمتة التوليد باستخدام CI.

### طباعة مصدر Mermaid إلى stdout

شغّل مهمة Rake المسماة `mermaid_erd:print` لطباعة مصدر `erDiagram` الخام إلى stdout بدلاً من كتابة عارض HTML. يمكن توجيه المخرجات مباشرةً إلى أدوات أخرى:

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

المخرجات تمثّل المخطط الكامل — كل الجداول والأعمدة والمفاتيح والتعليقات والعلاقات — ما يعادل عارض HTML مع تفعيل جميع مبدّلات التفاصيل.

## اللغات

تتوفر واجهة العارض بـ 12 لغة: English و日本語 و简体中文 و繁體中文 و한국어 وEspañol وFrançais وDeutsch وItaliano وPortuguês (Brasil) وРусский والعربية (من اليمين إلى اليسار). تُكتشف لغة المتصفح تلقائياً (`navigator.language`) عند التحميل، ويُستخدم الإنجليزية للغات غير المدعومة، كما يمكن التبديل يدوياً من خلال المحدِّد الموجود في الزاوية العلوية اليمنى.

## الإصدارات المدعومة

مجموعات Ruby × Rails التي يتحقق منها CI عند كل push وpull request:

| Rails | Ruby                             |
| ----- | -------------------------------- |
| 5.2   | 2.7                              |
| 6.0   | 2.7, 3.0                         |
| 6.1   | 2.7, 3.0, 3.1, 3.2, 3.3          |
| 7.0   | 2.7, 3.0, 3.1, 3.2, 3.3          |
| 7.1   | 3.1, 3.2, 3.3, 3.4               |
| 7.2   | 3.1, 3.2, 3.3, 3.4               |
| 8.0   | 3.2, 3.3, 3.4, 4.0               |
| 8.1   | 3.2, 3.3, 3.4, 4.0               |

قد تعمل مجموعات أخرى لكنها غير مُتحقَّق منها.

## الإعداد

ضع الملف `./config/mermaid_erd.yml` لتخصيص الإعدادات.
راجع [./docs/example.yml](./docs/example.yml) للاطلاع على مثال للإعداد.

عناصر الإعداد كالتالي:

| المفتاح | الوصف | الافتراضي |
| --- | --- | --- |
| `result_path` | مسار حفظ الملفات المولَّدة. | `mermaid_erd/index.html` |
| `ignore_tables` | مصفوفة من سلاسل التعبيرات النمطية. الجداول التي يطابق `table_name` الخاص بها أيَّ نمط تُستبعد من مخطط ERD المولَّد مع جميع العلاقات المرتبطة بها. مفيد لاستبعاد نماذج سجلات التدقيق أو الجداول المحذوفة منطقياً أو القديمة أو غيرها من الضوضاء التي لا تريد عرضها. تُصرَّف الأنماط باستخدام `Regexp.new`، لذا يجب تهريب الشرطات المائلة العكسية داخل سلاسل YAML (مثال: `"\\Aaudit_"`). | `[]` |
| `viewer_defaults` | العرض الذي يفتح به العارض عندما لا يحمل عنوان URL حالة محفوظة، والعرض الذي تعود إليه **إعادة تعيين**؛ والرابط الذي يحمل حالته الخاصة له الأولوية دائمًا. `models`: مصفوفة بأسماء النماذج المحددة في البداية (الاسم غير الموجود في ERD يتم تخطيه مع تحذير عند توليد الملف). `columns`: `all` أو `keys` (المفاتيح الأساسية والخارجية فقط) أو `none`، وهي نفس خيارات «الأعمدة» في الشريط الجانبي. مفيد لفتح تطبيق كبير على النماذج التي يبدأ بها الناس عادةً. | `models: []` (بدون تحديد)، `columns: all` |

## العلامات التجارية

هذا المشروع غير تابع لـ Rails أو The Rails Foundation أو مشروع Mermaid أو Mermaid Chart Inc.، ولم تعتمده هذه الجهات ولم ترعه. إن Rails وRuby on Rails علامتان تجاريتان مسجلتان لـ David Heinemeier Hansson. وقد سجّلت Mermaid Chart Inc. العلامتين التجاريتين MERMAID CHART وMERMAID في الولايات المتحدة أو قدّمت طلبًا لتسجيلهما. وتعود ملكية جميع العلامات التجارية الأخرى إلى أصحابها.

## الرخصة

يتوفر gem كبرنامج مفتوح المصدر وفق شروط [رخصة MIT](https://opensource.org/licenses/MIT).
