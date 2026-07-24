/// Hero tags for the flights into the canvas.
///
/// Every way into the canvas — a coloring page, a saved picture, a scene —
/// starts from a tile that already shows the picture. These tags are what
/// makes that picture fly into the paper sheet instead of the screen simply
/// being replaced.
///
/// One place on purpose: a tag that matches on only one side of a flight is
/// silently no flight at all, and that is a hard bug to see. Prefixed by
/// kind so a page id and an artwork id can never collide.
library;

String pageHeroTag(String pageId) => 'page-$pageId';

String artworkHeroTag(String artworkId) => 'artwork-$artworkId';

String sceneHeroTag(String sceneId) => 'scene-$sceneId';
