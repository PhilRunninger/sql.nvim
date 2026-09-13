"  vim: foldmethod=marker

syntax match SQLCatalogServer     /^\S.*/
syntax match SQLCatalogPlatform   /(.*)$/ containedin=SQLCatalogServer
syntax match SQLCatalogConcealed  /[()]/ conceal containedin=SQLCatalogPlatform
syntax match SQLCatalogDatabase   /^  \S.*/
syntax match SQLCatalogObjectType /^    \S.*/
syntax match SQLCatalogObject     /^      \S.*/
syntax match SQLCatalogObjectPart /^        \S.*/
syntax match SQLCatalogColumnInfo /{.*}/ containedin=SQLCatalogObject,SQLCatalogObjectPart
syntax match SQLCatalogConcealed  /[{}]/ conceal containedin=SQLCatalogColumnInfo

highlight default link SQLCatalogMark       Label
highlight default link SQLCatalogServer     Type
highlight default link SQLCatalogPlatform   Comment
highlight default link SQLCatalogDatabase   Function
highlight default link SQLCatalogObjectType Normal
highlight default link SQLCatalogObject     Special
highlight default link SQLCatalogColumnInfo Comment
