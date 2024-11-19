/**
 * UserField
 *
 * Return users and web users fields and userTvs
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category    snippet
 * @version    1.0
 * @internal @modx_category Users
 * @lastupdate  19-11-2024
 */


// [[UserField? &field=`fullname` &id=`123` &mode=`web`]]

// Retrieve the logged in user ID or use the ID parameter
$id = (isset($id) && (int)$id > 0) ? (int)$id : $modx->getLoginUserID(($mode == 'mgr' ? 'mgr' : 'web'));

if ($id > 0) {
    // Retrieve the required field
    if (isset($field) && $field != 'internalKey') {
        $data = ($mode == 'mgr') ? $modx->getUserInfo($id) : $modx->getWebUserInfo($id);
        if (isset($data[$field])) {
            return htmlspecialchars($data[$field]);
        }

        // If the field is not found, search in user TVs
        $data = ['id' => $id];
        try {
            $tvValues = \UserManager::getValues($data);
            if (isset($tvValues[$field])) {
                return htmlspecialchars($tvValues[$field]);
            }
        } catch (\Exception $e) {
            // We ignore any errors
        }
    } else {
        // If `field` is not set, returns the ID
        return $id;
    }
}

// If nothing is found, return an empty string
return '';