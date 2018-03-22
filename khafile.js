let project = new Project('PolyPainter');
project.addAssets('Assets/**');
project.addShaders('Shaders/**');
project.addSources('src');
resolve(project);