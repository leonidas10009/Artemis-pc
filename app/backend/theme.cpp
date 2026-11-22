#include "theme.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

Theme* Theme::s_Theme = nullptr;

Theme::Theme()
{
    loadThemes();

    QSettings settings;
    const QString saved = settings.value("ui/theme", "apollo").toString();
    if (m_themes.contains(saved)) {
        m_name = saved;
    }
    else {
        m_name = "apollo";
    }

    qInfo() << "Theme loaded:" << m_name;
}

Theme* Theme::get()
{
    if (!s_Theme) {
        s_Theme = new Theme();
    }

    return s_Theme;
}

QString Theme::name() const
{
    return m_name;
}

bool Theme::isDark() const
{
    return colors().value("dark").toBool();
}

QVariantMap Theme::colors() const
{
    return m_themes.value(m_name).toMap();
}

QStringList Theme::darkThemeKeys() const
{
    return m_darkKeys;
}

QStringList Theme::lightThemeKeys() const
{
    return m_lightKeys;
}

QString Theme::displayName(const QString& key) const
{
    return m_themes.value(key).toMap().value("label", key).toString();
}

QVariantMap Theme::colorsFor(const QString& key) const
{
    return m_themes.value(key).toMap();
}

void Theme::setTheme(const QString& theme)
{
    if (!m_themes.contains(theme) || m_name == theme) {
        return;
    }

    m_name = theme;

    QSettings settings;
    settings.setValue("ui/theme", theme);

    emit themeChanged();
}

QColor Theme::alpha(const QString& color, double alpha) const
{
    QColor c(color);
    c.setAlphaF(alpha);
    return c;
}

QString Theme::keyForIndex(int index) const
{
    if (index < 0 || index >= m_darkKeys.count()) {
        return QString();
    }

    return m_darkKeys.at(index);
}

void Theme::loadThemes()
{
    QFile file(":/data/themes.json");
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    if (doc.isNull() || !doc.isObject()) {
        return;
    }

    m_themes = doc.object().toVariantMap();

    static const QStringList darkOrder = {
        "apollo", "dark", "dracula", "mocha", "ember", "rose-pine",
        "moonlight", "slate", "midnight", "nord"
    };
    static const QStringList lightOrder = {
        "light", "alucard", "latte", "ember-light", "rose-pine-dawn",
        "sunshine", "indigo", "ocean", "forest", "rose", "lavender",
        "monochrome"
    };

    for (const QString& key : darkOrder) {
        if (m_themes.contains(key)) {
            m_darkKeys.append(key);
        }
    }

    for (const QString& key : lightOrder) {
        if (m_themes.contains(key)) {
            m_lightKeys.append(key);
        }
    }
}
