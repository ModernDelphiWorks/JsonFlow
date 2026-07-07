import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'intro',
      label: 'Documentation portal',
    },
    {
      type: 'category',
      label: 'Projects',
      items: [{ type: 'link', label: 'JsonFlow', href: '/jsonflow/' }],
    },
  ],
  jsonflowSidebar: [
    {
      type: 'category',
      label: 'JsonFlow',
      link: { type: 'doc', id: 'jsonflow/index' },
      items: [
        'jsonflow/introduction',
        {
          type: 'category',
          label: 'Getting Started',
          items: [
            'jsonflow/getting-started/installation',
            'jsonflow/getting-started/quickstart',
          ],
        },
        {
          type: 'category',
          label: 'Guides',
          items: [
            'jsonflow/guides/serialize-object-to-json',
            'jsonflow/guides/deserialize-json-to-object',
            'jsonflow/guides/fluent-writer',
            'jsonflow/guides/reader-parse',
            'jsonflow/guides/composer-dynamic-editing',
            'jsonflow/guides/schema-validation',
            'jsonflow/guides/serializer-attributes',
            'jsonflow/guides/middleware-pipeline',
            'jsonflow/guides/horse-middleware',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'jsonflow/reference/api',
            'jsonflow/reference/interfaces',
            'jsonflow/reference/validation-rules',
          ],
        },
        {
          type: 'category',
          label: 'Troubleshooting',
          items: ['jsonflow/troubleshooting/common-errors'],
        },
      ],
    },
  ],
};

export default sidebars;
