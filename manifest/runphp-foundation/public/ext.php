<?php
/**
 * Display extension information
 */
require_once __DIR__ . '/../src/Extensions.php';
$obj_ext = new \ThinkFluent\RunPHP\Extensions();
?><html>
<head>
    <title>runphp extensions</title>
</head>
<body>
<h2>Installed</h2>
<pre><?php echo implode(PHP_EOL, $obj_ext->fetchInstalledExtList()); ?></pre>
<h2>Enabled</h2>
<pre><?php echo implode(PHP_EOL, $obj_ext->fetchEnabledExtensions()); ?></pre>
</body>
</html>