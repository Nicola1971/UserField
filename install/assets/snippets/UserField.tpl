<?php
/**
 * UserField
 *
 * Displays user fields, user TVs, and user MultiTVs based on the parameter `fieldType`
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category    snippet
 * @version    2.0
 * @internal @modx_category Users
 * @lastupdate  01-12-2024
 */


// user field [[UserField? &field=`fullname` &id=`123`]]
// user tv field [[UserField? &fieldType=`tv` &field=`PrivacyAgreetv` &id=`123`]]
// user multitv field [[UserField? &fieldType=`multitv` &field=`eventmultitv` &id=`123` &rowTpl=`<li>Event: [+event+], Location: [+location+], Price: [+price+]</li>` &toPlaceholder=`1`]]

// Get input parameters
$field = isset($field) ? (string)$field : '';
$fieldType = isset($fieldType) ? (string)$fieldType : 'field';
$mode = isset($mode) ? (string)$mode : 'web';
$id = (isset($id) && (int)$id > 0) ? (int)$id : $modx->getLoginUserID(($mode === 'mgr' ? 'mgr' : 'web'));

// Validate user ID
if (!$id) {
    return '';
}

// Switch case to handle different field types
switch ($fieldType) {
    case 'field':
        // Handle standard user fields
        if (!empty($field) && $field !== 'internalKey') {
            $data = ($mode === 'mgr') ? $modx->getUserInfo($id) : $modx->getWebUserInfo($id);
            if (isset($data[$field])) {
                return htmlspecialchars($data[$field]);
            }
        }
        return $id;

    case 'tv':
        // Handle user TVs
        $data = ['id' => $id];
        try {
            $tvValues = \UserManager::getValues($data);
            if (isset($tvValues[$field])) {
                return htmlspecialchars($tvValues[$field]);
            }
        } catch (\Exception $e) {
            return ''; // Ignore errors
        }
        break;

    case 'multitv':
    // Handle MultiTVs
    $outerTpl = isset($outerTpl) ? $outerTpl : '<ul>[+wrapper+]</ul>';
    $rowTpl = isset($rowTpl) ? $rowTpl : '<li>Event: [+event+], Location: [+location+], Price: [+price+]</li>';
    $toPlaceholder = isset($toPlaceholder) ? $toPlaceholder : '';
    $display = isset($display) ? (int)$display : 5;
    $orderBy = isset($orderBy) ? $orderBy : '';
    $noResults = isset($noResults) ? $noResults : '<p>No data available.</p>';

    $data = ['id' => $id];

    try {
        $tvValues = \UserManager::getValues($data);
        if (isset($tvValues[$field])) {
            $multiTvData = json_decode($tvValues[$field], true);
            if (isset($multiTvData['fieldValue']) && is_array($multiTvData['fieldValue'])) {
                // Apply sorting
                if (!empty($orderBy)) {
                    $orderColumn = array_column($multiTvData['fieldValue'], $orderBy);
                    array_multisort($orderColumn, SORT_ASC, $multiTvData['fieldValue']);
                }

                // Limit rows
                $multiTvData['fieldValue'] = array_slice($multiTvData['fieldValue'], 0, $display);
                $rows = '';

                foreach ($multiTvData['fieldValue'] as $item) {
                    $placeholders = [];
                    foreach ($item as $key => $value) {
                        $placeholders['[+' . htmlspecialchars($key) . '+]'] = htmlspecialchars($value);
                    }

                    // Handle rowTpl: Check for @CODE or Chunk
                    if (strpos($rowTpl, '@CODE:') === 0) {
                        // Extract inline HTML
                        $tpl = substr($rowTpl, 6);
                    } else {
                        // Assume it's a chunk name
                        $tpl = $modx->getChunk($rowTpl);
                    }

                    // Replace placeholders
                    $row = strtr($tpl, $placeholders);
                    $rows .= $row;
                }

                $output = strtr($outerTpl, ['[+wrapper+]' => $rows]);

                // Manage output
                if (!empty($toPlaceholder)) {
                    $modx->setPlaceholder($toPlaceholder, $output);
                } else {
                    return $output;
                }
            } else {
                // If no rows, manage the "no results" case
                if (!empty($toPlaceholder)) {
                    $modx->setPlaceholder($toPlaceholder, $noResults);
                } else {
                    return $noResults;
                }
            }
        } else {
            // Field not found
            return '<p>No MultiTV data found for field: ' . htmlspecialchars($field) . '</p>';
        }
    } catch (\Exception $e) {
        // Handle exceptions
        return '<p>Error: ' . htmlspecialchars($e->getMessage()) . '</p>';
    }
    break;

    default:
        return '<p>Invalid field type specified.</p>';
}