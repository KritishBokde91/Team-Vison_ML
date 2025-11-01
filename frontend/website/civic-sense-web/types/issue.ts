// src/types/issue.ts
export type Issue = {
  id: string;
  title: string;
  description: string | null;
  category: string | null;
  priority: string | null;
  location: string | null;
  coordinates?: { lat: number; lng: number } | null;
  images?: string[] | null;
  status: "pending" | "in_progress" | "resolved";
  reported_at: string;
  reported_by?: { full_name: string } | null;
  assigned_to?: { full_name: string } | null;
  sla_deadline?: string | null;
};

export type IssueUpdate = {
  id: string;
  issue_id: string;
  user_id: string;
  message: string;
  created_at: string;
  user?: { full_name: string } | null;
};
