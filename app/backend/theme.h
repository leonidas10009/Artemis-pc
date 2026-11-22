#pragma once

#include <QObject>
#include <QVariantMap>
#include <QStringList>
#include <QColor>

class Theme : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name NOTIFY themeChanged)
    Q_PROPERTY(bool isDark READ isDark NOTIFY themeChanged)
    Q_PROPERTY(QVariantMap colors READ colors NOTIFY themeChanged)
    Q_PROPERTY(QStringList darkThemeKeys READ darkThemeKeys CONSTANT)
    Q_PROPERTY(QStringList lightThemeKeys READ lightThemeKeys CONSTANT)

public:
    static Theme* get();

    QString name() const;
    bool isDark() const;
    QVariantMap colors() const;
    QStringList darkThemeKeys() const;
    QStringList lightThemeKeys() const;

    Q_INVOKABLE QString displayName(const QString& key) const;
    Q_INVOKABLE QVariantMap colorsFor(const QString& key) const;
    Q_INVOKABLE void setTheme(const QString& theme);
    Q_INVOKABLE QColor alpha(const QString& color, double alpha) const;
    Q_INVOKABLE QString keyForIndex(int index) const;

signals:
    void themeChanged();

private:
    explicit Theme();

    void loadThemes();

    QVariantMap m_themes;
    QString m_name;
    QStringList m_darkKeys;
    QStringList m_lightKeys;

    static Theme* s_Theme;
};
