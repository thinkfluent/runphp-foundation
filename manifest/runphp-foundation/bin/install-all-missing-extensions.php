<?php
/**
 * Called during image build phase
 *
 * Attempt to install all available PHP extensions.
 *
 * @author Tom Walder <tom@thinkfluent.co.uk>
 */

namespace ThinkFluent\RunPHP;

require_once __DIR__ . '/../src/Extensions.php';
require_once __DIR__ . '/../src/ExtensionBuilder.php';

(new ExtensionBuilder)->run();
