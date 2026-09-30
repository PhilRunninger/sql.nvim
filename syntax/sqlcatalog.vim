"  vim: foldmethod=marker

syntax match SQLCatalogServer     /^\S.*/ contains=SQLCatalogExplored,SQLCatalogUnexplored,SQLCatalogPlatform
syntax match SQLCatalogDatabase   /^  \S.*/ contains=SQLCatalogExplored,SQLCatalogUnexplored
syntax match SQLCatalogObjectType /^    \S.*/
syntax match SQLCatalogObject     /^      \S.*/ contains=SQLCatalogColumnInfo
syntax match SQLCatalogObjectPart /^        \S.*/ contains=SQLCatalogColumnInfo

syntax match SQLCatalogPlatform   /(.*)$/ contained
syntax match SQLCatalogColumnInfo /{.*}/ contained
execute 'syntax match SQLCatalogExplored   /'..g:sql#explored..'/ contained'
execute 'syntax match SQLCatalogUnexplored /'..g:sql#unexplored..'/ contained'

syntax match SQLCatalogConcealed  /[()]/ conceal containedin=SQLCatalogPlatform
syntax match SQLCatalogConcealed  /[{}]/ conceal containedin=SQLCatalogColumnInfo

highlight default link SQLCatalogMark       Label
highlight default link SQLCatalogServer     Function
highlight default link SQLCatalogPlatform   Comment
highlight default link SQLCatalogDatabase   Identifier
highlight default link SQLCatalogObjectType Normal
highlight default link SQLCatalogObject     String
highlight default link SQLCatalogColumnInfo Comment
highlight default link SQLCatalogExplored   Special
highlight default link SQLCatalogUnexplored Ignore

