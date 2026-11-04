<?php

use Glpi\Plugin\Hooks;
use GlpiPlugin\Ninjaone\Config;
use GlpiPlugin\Ninjaone\DeviceMapping;
use GlpiPlugin\Ninjaone\LocationMapping;
use GlpiPlugin\Ninjaone\OrganizationMapping;
use GlpiPlugin\Ninjaone\ComputerLink;
use GlpiPlugin\Ninjaone\SyncLog;

define('PLUGIN_NINJAONE_VERSION', '0.2.0');
define('PLUGIN_NINJAONE_SCHEMA_VERSION', '1.1.0');
define('PLUGIN_NINJAONE_MIN_GLPI_VERSION', '12.0.0');
define('PLUGIN_NINJAONE_MAX_GLPI_VERSION', '12.1.0');

function plugin_init_ninjaone(): void
{
    global $PLUGIN_HOOKS;

    Plugin::loadLang('ninjaone');

    Plugin::registerClass(Config::class);
    Plugin::registerClass(SyncLog::class);
    Plugin::registerClass(OrganizationMapping::class);
    Plugin::registerClass(LocationMapping::class);
    Plugin::registerClass(DeviceMapping::class);
    Plugin::registerClass(ComputerLink::class, [
        'addtabon' => [
            Computer::class,
        ],
    ]);

    if (Session::haveRight('config', UPDATE)) {
        $PLUGIN_HOOKS[Hooks::CONFIG_PAGE]['ninjaone'] = 'front/config.php';
    }
    $PLUGIN_HOOKS[Hooks::MENU_TOADD]['ninjaone'] = [
        'plugins' => Config::class,
    ];
    $PLUGIN_HOOKS['pre_item_form']['ninjaone'] = [ComputerLink::class, 'preItemForm'];
}

function plugin_version_ninjaone(): array
{
    return [
        'name'           => 'NinjaOne connector',
        'version'        => PLUGIN_NINJAONE_VERSION,
        'author'         => 'TiniSys IT Solutions',
        'license'        => 'GPLv3+',
        'homepage'       => 'https://github.com/TiniSys-IT-Solutions/glpi-ninjaone-connector',
        'requirements'   => [
            'glpi' => [
                'min' => PLUGIN_NINJAONE_MIN_GLPI_VERSION,
                'max' => PLUGIN_NINJAONE_MAX_GLPI_VERSION,
            ],
            'php' => [
                'min'  => '8.3',
                'exts' => [
                    'curl' => [
                        'required' => true,
                    ],
                    'json' => [
                        'required' => true,
                    ],
                    'openssl' => [
                        'required' => true,
                    ],
                ],
            ],
        ],
    ];
}

function plugin_ninjaone_check_prerequisites(): bool
{
    if (
        !defined('GLPI_VERSION')
        || version_compare(GLPI_VERSION, PLUGIN_NINJAONE_MIN_GLPI_VERSION, '<')
        || version_compare(GLPI_VERSION, PLUGIN_NINJAONE_MAX_GLPI_VERSION, '>=')
        || version_compare(PHP_VERSION, '8.3.0', '<')
    ) {
        echo 'This plugin requires GLPI 12.0.x and PHP 8.3 or newer.';
        return false;
    }

    return true;
}

function plugin_ninjaone_check_config(bool $verbose = false): bool
{
    return true;
}
