import 'package:flutter/foundation.dart';

/// Licence notices for the optional AI models (TASK-C3 §1). Always
/// registered (short text); they show on the About → licences page.
void registerAiLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['EfficientNet-Lite0 (int8)', 'EfficientDet-Lite0'],
      'Optional on-device AI models, downloaded only when you choose to. '
      'Copyright Google LLC / The TensorFlow Authors.\n\n'
      'Licensed under the Apache License, Version 2.0 (the "License"); you '
      'may not use these files except in compliance with the License. You '
      'may obtain a copy of the License at\n\n'
      '    http://www.apache.org/licenses/LICENSE-2.0\n\n'
      'Unless required by applicable law or agreed to in writing, software '
      'distributed under the License is distributed on an "AS IS" BASIS, '
      'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or '
      'implied. See the License for the specific language governing '
      'permissions and limitations under the License.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['COCO category names'],
      "The object detector's category names come from the COCO dataset "
      '(cocodataset.org), (c) COCO Consortium, licensed under the Creative '
      'Commons Attribution 4.0 License (CC BY 4.0), '
      'https://creativecommons.org/licenses/by/4.0/.',
    );
  });
}
