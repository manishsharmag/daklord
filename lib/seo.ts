import { SEOMetadata, SchemaJsonLd, BreadcrumbItem } from '@/types';

export function generateMetadata(meta: SEOMetadata) {
  return {
    title: meta.title,
    description: meta.description,
    keywords: meta.keywords?.join(','),
    robots: meta.robots || 'index, follow',
    author: meta.author,
    openGraph: {
      title: meta.ogTitle || meta.title,
      description: meta.ogDescription || meta.description,
      type: meta.ogType || 'website',
      url: meta.canonical,
      images: meta.ogImage
        ? [
            {
              url: meta.ogImage,
              width: 1200,
              height: 630,
              alt: meta.ogTitle || meta.title,
            },
          ]
        : undefined,
    },
    twitter: {
      card: meta.twitterCard || 'summary_large_image',
      title: meta.ogTitle || meta.title,
      description: meta.ogDescription || meta.description,
      images: meta.ogImage ? [meta.ogImage] : undefined,
    },
    alternates: {
      canonical: meta.canonical,
    },
    verification: {
      google: process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION,
    },
  };
}

export function generateJobPostingSchema(job: any): SchemaJsonLd {
  return {
    '@context': 'https://schema.org',
    '@type': 'JobPosting',
    title: job.title,
    description: job.description,
    hiringOrganization: {
      '@type': 'Organization',
      name: job.company,
      logo: job.imageUrl,
    },
    jobLocation: {
      '@type': 'Place',
      address: {
        '@type': 'PostalAddress',
        addressLocality: job.location,
      },
    },
    baseSalary: job.salary
      ? {
          '@type': 'PriceSpecification',
          priceCurrency: 'INR',
          price: job.salary,
        }
      : undefined,
    employmentType: job.jobType,
    datePosted: job.postedDate,
    validThrough: job.expiryDate,
    applicantLocationRequirements: {
      '@type': 'Country',
      name: 'IN',
    },
    applicationContact: {
      '@type': 'ContactPoint',
      contactType: 'Application',
      url: job.applicationUrl,
    },
  };
}

export function generateNewsArticleSchema(article: any): SchemaJsonLd {
  return {
    '@context': 'https://schema.org',
    '@type': 'NewsArticle',
    headline: article.title,
    description: article.description,
    image: article.imageUrl,
    datePublished: article.publishedAt || article.releaseDate,
    dateModified: article.updatedAt,
    author: {
      '@type': 'Organization',
      name: process.env.NEXT_PUBLIC_SITE_NAME || 'Public Portal',
    },
    publisher: {
      '@type': 'Organization',
      name: process.env.NEXT_PUBLIC_SITE_NAME || 'Public Portal',
      logo: {
        '@type': 'ImageObject',
        url: process.env.NEXT_PUBLIC_SITE_URL + '/logo.png',
      },
    },
  };
}

export function generateBreadcrumbSchema(items: BreadcrumbItem[]): SchemaJsonLd {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: `${process.env.NEXT_PUBLIC_SITE_URL}${item.url}`,
    })),
  };
}

export function generateOrganizationSchema(): SchemaJsonLd {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: process.env.NEXT_PUBLIC_SITE_NAME || 'Public Portal',
    description: process.env.NEXT_PUBLIC_SITE_DESCRIPTION || '',
    url: process.env.NEXT_PUBLIC_SITE_URL,
    logo: `${process.env.NEXT_PUBLIC_SITE_URL}/logo.png`,
    sameAs: [
      'https://www.facebook.com/yourpage',
      'https://twitter.com/yourpage',
      'https://www.linkedin.com/company/yourpage',
    ],
  };
}

export function generateImageSchema(
  imageUrl: string,
  title: string,
  description?: string
): SchemaJsonLd {
  return {
    '@context': 'https://schema.org',
    '@type': 'ImageObject',
    url: imageUrl,
    name: title,
    description,
  };
}
