<?php

namespace ThinkFluent\RunPHP;

/**
 * ExtensionBuilder
 *
 * @package ThinkFluent\RunPHP
 */
class ExtensionBuilder extends Extensions
{
    /**
     * Run the detection & build process
     */
    public function run()
    {
        $arr_to_skip = ['enchant', 'zend_test'];

        // (1) list of enabled extensions. This will include system extensions.
        $arr_enabled_extensions = $this->fetchEnabledExtensions();
        echo "Enabled: ", implode(' ', $arr_enabled_extensions), PHP_EOL;

        // (2) list of installed extensions
        $arr_installed_extensions = $this->fetchInstalledExtList();
        echo "Installed: ", implode(' ', $arr_installed_extensions), PHP_EOL;

        // (3) list of available extensions - method borrowed from https://github.com/docker-library/php/blob/master/docker-php-ext-install
        $arr_possible_extensions = $this->fetchPossibleExtList();
        echo "Possible: ", implode(' ', $arr_possible_extensions), PHP_EOL;

        // (4) produce gap list [3 - (1+2)]
        $arr_to_install = array_diff($arr_possible_extensions, $arr_enabled_extensions, $arr_installed_extensions, $arr_to_skip);

        // (5) install gap list.
        // We do this one at a time so we can have better visibility of failures
        // We also "ignore" failures - as we're trying to build as many extensions as we easily can
        foreach ($arr_to_install as $str_extension) {
            $str_install_cmd = 'docker-php-ext-install ' . $str_extension;
            echo PHP_EOL, str_repeat('-', 80), PHP_EOL;
            echo "Running: ", $str_install_cmd, PHP_EOL;
            system($str_install_cmd);
        }
    }

    /**
     * Fetch a list of the available extensions in php-source
     *
     * @return string[]
     */
    protected function fetchPossibleExtList()
    {
        shell_exec('docker-php-source extract');
        $arr_possible_extensions = explode(' ', trim(shell_exec("find /usr/src/php/ext -mindepth 2 -maxdepth 2 -type f -name 'config.m4' | xargs -n1 dirname | xargs -n1 basename | sort | xargs")));
        shell_exec('docker-php-source delete');
        return $arr_possible_extensions;
    }
}
