export interface Issue {
  id: string;
  title: string;
  description: string;
  category: string;
  priority: string;
  location: string;
  coordinates: { lat: number; lng: number };
  images: File[];
  status: string;
  reportedAt: string;
  reportedBy: string;
}