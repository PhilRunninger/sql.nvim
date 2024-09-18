syntax match SQLCatalogObjectType /^\S.*/
syntax match SQLCatalogObject     /^  \S.*/
syntax match SQLCatalogObjectPart /^    \S.*/
syntax match SQLCatalogColumnInfo /{.*}/ containedin=SQLCatalogObject,SQLCatalogObjectPart
syntax match SQLCatalogConcealed  /[{}]/ conceal containedin=SQLCatalogColumnInfo
syntax match SQLCatalogConcealed /dbo\./ conceal containedin=SQLCatalogObject

highlight default link SQLCatalogObjectType Title
highlight default link SQLCatalogObject     Special
highlight default link SQLCatalogColumnInfo Comment
