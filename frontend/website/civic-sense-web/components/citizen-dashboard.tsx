"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { MapPin, Plus, AlertCircle } from "lucide-react";
import { IssueReportForm } from "@/components/issue-report-form";
import { createClient } from "@/utils/supabase/client";
import type { Issue } from "@/types/issue";

const supabase = createClient();

// const getStatusIcon = (status: string) => {
//   switch (status) {
//     case "resolved":
//       return <CheckCircle className="w-4 h-4 text-green-600" />;
//     case "in_progress":
//       return <Clock className="w-4 h-4 text-yellow-600" />;
//     case "pending":
//       return <AlertCircle className="w-4 h-4 text-red-600" />;
//     default:
//       return null;
//   }
// };

const getStatusColor = (status: string) => {
  switch (status) {
    case "resolved":
      return "bg-green-100 text-green-800";
    case "in_progress":
      return "bg-yellow-100 text-yellow-800";
    case "pending":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

export default function CitizenDashboard() {
  const [issues, setIssues] = useState<Issue[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchIssues = async () => {
      const { data: userData } = await supabase.auth.getUser();
      const userId = userData.user?.id;
      if (!userId) return;

      const { data, error } = await supabase
        .from("issues")
        .select(
          `
          id,
          title,
          description,
          category,
          priority,
          location,
          coordinates,
          images,
          status,
          reported_at,
          reported_by: users(full_name),
          assigned_to: users (full_name)
        `
        )
        .eq("reported_by", userId)
        .order("reported_at", { ascending: false });

      if (error) {
        console.error(error);
        alert(error.message);
        setIsLoading(false);
        return;
      }

      const formatted: Issue[] = (data || []).map((i) => ({
        ...i,
        coordinates: i.coordinates ? JSON.parse(i.coordinates) : null,
        reported_by: i.reported_by?.[0] ?? null,
        assigned_to: i.assigned_to?.[0] ?? null,
      }));

      setIssues(formatted);
      setIsLoading(false);
    };

    fetchIssues();

    const channel = supabase
      .channel("citizen_issues")
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "issues",
          filter: `reported_by=eq.${(async () =>
            (await supabase.auth.getUser()).data.user?.id)()}`,
        },
        () => fetchIssues()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleNewIssue = (issue: Issue) => {
    setIssues((prev) => [issue, ...prev]);
    setShowForm(false);
  };

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-7xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              My Reported Issues
            </h1>
            <p className="text-gray-600">
              Track the status of issues you reported
            </p>
          </div>
          <Button onClick={() => setShowForm(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Report Issue
          </Button>
        </div>

        {isLoading ? (
          <p className="text-center py-8">Loading your issues...</p>
        ) : issues.length === 0 ? (
          <Card>
            <CardContent className="p-12 text-center">
              <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-600">No issues reported yet.</p>
              <Button className="mt-4" onClick={() => setShowForm(true)}>
                Report Your First Issue
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {issues.map((issue) => (
              <Card
                key={issue.id}
                className="hover:shadow-lg transition-shadow"
              >
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">{issue.title}</CardTitle>
                    <Badge className={getStatusColor(issue.status)}>
                      {issue.status.replace("_", " ")}
                    </Badge>
                  </div>
                  <CardDescription>{issue.category}</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-gray-600 mb-4">
                    {issue.description}
                  </p>
                  <div className="flex items-center space-x-2 text-sm text-gray-500">
                    <MapPin className="w-4 h-4" />
                    <span>{issue.location}</span>
                  </div>
                  {issue.assigned_to && (
                    <p className="text-sm text-gray-600 mt-2">
                      Assigned to: {issue.assigned_to.full_name}
                    </p>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>

      {showForm && (
        <IssueReportForm
          onClose={() => setShowForm(false)}
          onSubmit={handleNewIssue}
        />
      )}
    </div>
  );
}
