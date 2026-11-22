#include <QtTest>
#include <QSettings>
#include <QTemporaryDir>

#include "backend/theme.h"
#include "backend/nvapp.h"

class ThemeTest : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QVERIFY(m_tempDir.isValid());

        QCoreApplication::setOrganizationName("ArtemisTest");
        QCoreApplication::setApplicationName("ArtemisTest");
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, m_tempDir.path());
        QSettings::setPath(QSettings::IniFormat, QSettings::SystemScope, m_tempDir.path());
    }

    void catalogIsComplete()
    {
        Theme* theme = Theme::get();

        QCOMPARE(theme->darkThemeKeys().size(), 10);
        QCOMPARE(theme->lightThemeKeys().size(), 12);
        QCOMPARE(theme->darkThemeKeys().size() + theme->lightThemeKeys().size(), 22);
    }

    void everyThemeHasRequiredTokens()
    {
        Theme* theme = Theme::get();
        const QStringList required = {
            "bgBase", "bgMuted", "border", "danger", "primary",
            "surface", "surfaceRaised", "textBase", "textMuted", "textSubtle"
        };

        QStringList keys = theme->darkThemeKeys();
        keys += theme->lightThemeKeys();

        for (const QString& key : keys) {
            const QVariantMap colors = theme->colorsFor(key);
            QVERIFY2(!colors.isEmpty(), qPrintable("Empty theme: " + key));

            for (const QString& token : required) {
                QVERIFY2(colors.contains(token),
                         qPrintable(QString("%1 is missing token %2").arg(key, token)));
            }
        }
    }

    void desktopAppDetection()
    {
        NvApp app;

        app.name = "Desktop";
        QVERIFY(app.isDesktopApp());

        app.name = "Escritorio";
        QVERIFY(app.isDesktopApp());

        // A game whose name merely starts with "Desktop" must not be treated
        // as the remote desktop, because that would enable Ctrl+F5...F10 in a
        // game and steal its shortcuts.
        app.name = "Desktop Dungeons";
        QVERIFY(!app.isDesktopApp());

        app.name = "Steam";
        QVERIFY(!app.isDesktopApp());
    }

    void displayNamesAndAlpha()
    {
        Theme* theme = Theme::get();

        QCOMPARE(theme->displayName("nord"), QString("Nord"));
        QCOMPARE(theme->displayName("does-not-exist"), QString("does-not-exist"));

        const QColor color = theme->alpha("#ff0000", 0.5);
        QVERIFY(color.alpha() == 127 || color.alpha() == 128);
    }

    void themeSelectionPersistsAndSignals()
    {
        Theme* theme = Theme::get();
        QSignalSpy spy(theme, &Theme::themeChanged);

        theme->setTheme("nord");
        QCOMPARE(theme->name(), QString("nord"));
        QVERIFY(theme->isDark());
        QCOMPARE(spy.count(), 1);

        // Setting the same theme again is a no-op.
        theme->setTheme("nord");
        QCOMPARE(spy.count(), 1);

        // Unknown themes must not change the current selection.
        theme->setTheme("does-not-exist");
        QCOMPARE(theme->name(), QString("nord"));

        QSettings settings;
        QCOMPARE(settings.value("ui/theme").toString(), QString("nord"));
    }

private:
    QTemporaryDir m_tempDir;
};

QTEST_GUILESS_MAIN(ThemeTest)
#include "theme_test.moc"
