class ProductImageResolver {
  ProductImageResolver._();

  static const List<String> _assetPaths = [
    'lib/imgs/products/beer/Bernard Świąteczny.png',
    'lib/imgs/products/beer/Browar Jabłonowo.png',
    'lib/imgs/products/beer/Cieszyn Wheat.png',
    'lib/imgs/products/beer/Heineken.png',
    'lib/imgs/products/beer/Karmi Classic.png',
    'lib/imgs/products/beer/Lech free.png',
    'lib/imgs/products/beer/Okocim.png',
    'lib/imgs/products/beer/Paropramen.png',
    'lib/imgs/products/beer/Piwo rzemieślnicze mazurskie.png',
    'lib/imgs/products/beer/Tatra jasna.png',
    'lib/imgs/products/beer/Warka Radler Mix.png',
    'lib/imgs/products/beer/Zatecki Svetly Lezak.png',
    'lib/imgs/products/liqueur/Aperol.png',
    'lib/imgs/products/liqueur/Baileys.png',
    'lib/imgs/products/liqueur/Carolans.png',
    'lib/imgs/products/liqueur/Cointreau.png',
    'lib/imgs/products/liqueur/Disaronno.png',
    'lib/imgs/products/liqueur/Drambuie.png',
    'lib/imgs/products/liqueur/Grand Marnier.png',
    'lib/imgs/products/liqueur/Jagermeister.png',
    'lib/imgs/products/liqueur/Kahlua likier kawowy.png',
    'lib/imgs/products/liqueur/Malibu.png',
    'lib/imgs/products/liqueur/Passoa.png',
    'lib/imgs/products/liqueur/Pigwówka.png',
    'lib/imgs/products/liqueur/Sheridan_s.png',
    'lib/imgs/products/rum/Bacardi Carta Blanca.png',
    'lib/imgs/products/rum/Bacardi Carta Negra.png',
    'lib/imgs/products/rum/Bacardi Carta Oro.png',
    'lib/imgs/products/rum/Botucal Reserva Exclusiva.png',
    'lib/imgs/products/rum/Botucal rum.png',
    'lib/imgs/products/rum/Bumbu XO.png',
    'lib/imgs/products/rum/Bumbu.png',
    'lib/imgs/products/rum/Captain Morgan Dark Rum.png',
    'lib/imgs/products/rum/Captain Morgan Spiced Gold.png',
    'lib/imgs/products/rum/Dictador 12.png',
    'lib/imgs/products/rum/Don Papa Masskara.png',
    'lib/imgs/products/rum/Eminente Ron De Cuba.png',
    'lib/imgs/products/rum/Rum Kraken.png',
    'lib/imgs/products/vodka/Absolut Vodka.png',
    'lib/imgs/products/vodka/Belvedere.png',
    'lib/imgs/products/vodka/Biały Bocian.png',
    'lib/imgs/products/vodka/Czarna Olcha.png',
    'lib/imgs/products/vodka/Finlandia.png',
    'lib/imgs/products/vodka/J. A. Baczewski.png',
    'lib/imgs/products/vodka/Ogiński Vodka.png',
    'lib/imgs/products/vodka/Pan Tadeusz.png',
    'lib/imgs/products/vodka/Soplica.png',
    'lib/imgs/products/vodka/Stumbras Vodka.png',
    'lib/imgs/products/vodka/Wyborowa.png',
    'lib/imgs/products/vodka/Wódka Ostoya.png',
    'lib/imgs/products/whisky/Aberlour 12.png',
    'lib/imgs/products/whisky/Ardbeg 10 y.o. Single Malt.png',
    'lib/imgs/products/whisky/Ardbeg 8.png',
    'lib/imgs/products/whisky/Auchentoshan 12.png',
    'lib/imgs/products/whisky/Auchentoshan Three Wood.png',
    'lib/imgs/products/whisky/Ballantine_s Brasil.png',
    'lib/imgs/products/whisky/Ballantine_s Finest.png',
    'lib/imgs/products/whisky/Balvenie 12.png',
    'lib/imgs/products/whisky/Bulleit Bourbon Frontier Whiskey.png',
    'lib/imgs/products/whisky/Bulleit Rye Burbon.png',
    'lib/imgs/products/whisky/Bushmills Black Bush.png',
    'lib/imgs/products/whisky/Bushmills Original.png',
    'lib/imgs/products/whisky/Gentleman Jack Tennessee Whiskey.png',
    'lib/imgs/products/whisky/Hibiki Suntory Whisky.png',
    'lib/imgs/products/whisky/Jack Daniel_s Single Barrel.png',
    'lib/imgs/products/whisky/Jack Daniel_s Tennessee Fire.png',
    'lib/imgs/products/whisky/Jack Daniel_s Tennessee Honey.png',
    'lib/imgs/products/whisky/Jack Daniel_s Tennessee Whiskey.png',
    'lib/imgs/products/whisky/Knob Creek.png',
    'lib/imgs/products/whisky/Macallan 18 Double Cask.png',
    'lib/imgs/products/whisky/Macallan Rare Cask 2023.png',
    'lib/imgs/products/whisky/Nikka Whisky From The Barrel.png',
    'lib/imgs/products/whisky/Tenjaku Blended Japanese Whisky.png',
    'lib/imgs/products/whisky/Tenjaku Whisky Pure Malt.png',
    'lib/imgs/products/whisky/The Chita whisky.png',
    'lib/imgs/products/whisky/Tullamore Dew.png',
    'lib/imgs/products/wine/Chardonnay 2022.png',
    'lib/imgs/products/wine/CIN&CIN.png',
    'lib/imgs/products/wine/Grzaniec Benedyktyński.png',
    'lib/imgs/products/wine/Pet-Nat brut białe.png',
    'lib/imgs/products/wine/Pet-Nat brut czerwone.png',
    'lib/imgs/products/wine/Rosé Reserva.png',
    'lib/imgs/products/wine/Wino Gruszkowe Musujące.png',
    'lib/imgs/products/wine/Wino Jagodowe Słodkie.png',
    'lib/imgs/products/wine/Wino Mirabelka Słodkie.png',
    'lib/imgs/products/wine/Wino z Aronii Ekologiczne Wytrawne.png',
    'lib/imgs/products/wine/Zachowickie półsłodkie czerwone.png',
  ];

  static final Map<String, String> _assetByNormalizedName = {
    for (final path in _assetPaths) _normalize(_fileNameWithoutExt(path)): path,
  };

  static String? findAssetForName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = _normalize(value);
    if (normalized.isEmpty) {
      return null;
    }

    final exact = _assetByNormalizedName[normalized];
    if (exact != null) {
      return exact;
    }

    String? bestPath;
    var bestScore = 0;

    _assetByNormalizedName.forEach((assetName, assetPath) {
      if (!normalized.contains(assetName) && !assetName.contains(normalized)) {
        return;
      }
      final score = assetName.length;
      if (score > bestScore) {
        bestScore = score;
        bestPath = assetPath;
      }
    });

    return bestPath;
  }

  static String? findAssetForNames(Iterable<String> values) {
    for (final value in values) {
      final match = findAssetForName(value);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  static String _fileNameWithoutExt(String path) {
    final slashIndex = path.lastIndexOf('/');
    final fileName = slashIndex >= 0 ? path.substring(slashIndex + 1) : path;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  static String _normalize(String input) {
    var normalized = input.toLowerCase().trim();

    const replacements = {
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ź': 'z',
      'ż': 'z',
      'é': 'e',
      'ö': 'o',
      'ü': 'u',
      '_': ' ',
      '&': ' ',
      '.': ' ',
      ',': ' ',
      '-': ' ',
      '/': ' ',
      '\\': ' ',
      "'": ' ',
      '"': ' ',
    };

    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }
}
