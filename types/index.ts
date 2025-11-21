export interface PaginationParams {
  page?: number;
  limit?: number;
  search?: string;
  sort?: string;
  order?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface JobFilter {
  jobType?: string;
  location?: string;
  company?: string;
  minSalary?: number;
  maxSalary?: number;
}

export interface SEOMetadata {
  title: string;
  description: string;
  canonical?: string;
  ogTitle?: string;
  ogDescription?: string;
  ogImage?: string;
  ogType?: string;
  twitterCard?: string;
  keywords?: string[];
  robots?: string;
  author?: string;
  publishedTime?: string;
  modifiedTime?: string;
  section?: string;
  tags?: string[];
}

export interface BreadcrumbItem {
  name: string;
  url: string;
}

export interface SchemaJsonLd {
  '@context': string;
  '@type': string;
  [key: string]: any;
}

export interface BookmarkState {
  resultId?: string;
  noticeId?: string;
  jobPostingId?: string;
  admitCardId?: string;
  previousPaperId?: string;
  resourceId?: string;
  isBookmarked: boolean;
}
