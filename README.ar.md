[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> هذه ترجمة لـ [README الإنجليزي](./README.md). عند وجود أي تعارض، تُعدّ النسخة الإنجليزية هي المرجع الرسمي.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

توليد [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) من تطبيق Ruby on Rails الخاص بك.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[صفحة العرض التوضيحي](https://koedame.github.io/rails-mermaid_erd/example.html)

يمكن توليد مخطط ERD في أي وقت.
يمكن نسخ المخطط المولَّد بصيغة Markdown، مما يسهّل مشاركته على GitHub.
كما يمكن حفظه كصورة، فيصبح مفيداً في البيئات التي لا يتوفر فيها Mermaid.
المحرر عبارة عن ملف HTML واحد يمكن مشاركته بالكامل مع الآخرين.

## التثبيت

أضف هذا السطر إلى ملف Gemfile في تطبيقك:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

ثم نفّذ:

```bash
$ bundle install
```

أضف هذه الأسطر إلى ملف Rakefile في تطبيقك:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## الاستخدام

تشغيل مهمة Rake المسماة `mermaid_erd` سيولّد الملف `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

افتح الملف المولَّد `<app_root>/mermaid_erd/index.html` مباشرةً في متصفحك.

لا يلزم إضافة هذا الملف إلى إدارة Git، لذا يمكنك استثناؤه عبر `.gitignore` عند الحاجة:

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` ملف HTML مكتفٍ بذاته. جميع التبعيات الأمامية (Tailwind وMermaid وVue) مضمَّنة فيه، لذا يعمل دون اتصال بالإنترنت وخلف وكلاء الشركات الصارمة — لا حاجة للوصول إلى أي CDN عند العرض. حجم الملف نحو 4 ميغابايت بسبب الحزم المدمجة.

إذا شاركت هذا الملف، أمكن استخدامه لمن لا تتوفر لديهم بيئة Ruby on Rails. كما يمكنك رفعه على خادم ويب ومشاركته عبر رابط موحّد.

من الأنسب جداً أتمتة التوليد باستخدام CI.

### طباعة مصدر Mermaid إلى stdout

شغّل مهمة Rake المسماة `mermaid_erd:print` لطباعة مصدر `erDiagram` الخام إلى stdout بدلاً من كتابة عارض HTML. يمكن توجيه المخرجات مباشرةً إلى أدوات أخرى:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
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
| 6.1   | 2.7, 3.0, 3.1, 3.2               |
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

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## الرخصة

يتوفر gem كبرنامج مفتوح المصدر وفق شروط [رخصة MIT](https://opensource.org/licenses/MIT).
