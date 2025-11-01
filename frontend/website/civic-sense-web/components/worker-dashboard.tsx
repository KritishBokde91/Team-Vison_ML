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
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Textarea } from "@/components/ui/textarea";
import {
  MapPin,
  Bell,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  Navigation,
  MessageSquare,
} from "lucide-react";
import { useAuth } from "@/hook/use-auth";
import { createClient } from "@/utils/supabase/client";
import type { Issue, IssueUpdate } from "@/types/issue";

const supabase = createClient();

const getStatusIcon = (status: string) => {
  switch (status) {
    case "resolved":
      return <CheckCircle className="w-4 h-4 text-green-600" />;
    case "in_progress":
      return <Clock className="w-4 h-4 text-yellow-600" />;
    case "pending":
      return <AlertCircle className="w-4 h-4 text-red-600" />;
    default:
      return null;
  }
};

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

export function WorkerDashboard() {
  const { user } = useAuth();
  const [issues, setIssues] = useState<Issue[]>([]);
  const [updates, setUpdates] = useState<IssueUpdate[]>([]);
  const [selectedIssueId, setSelectedIssueId] = useState<string | null>(null);
  const [newUpdate, setNewUpdate] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  // === FETCH ISSUES ===
  useEffect(() => {
    if (!user) return;

    const fetchData = async () => {
      setIsLoading(true);

      const { data: issueData, error: issueError } = await supabase
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
          status,
          reported_at,
          sla_deadline,
          reported_by:reportedBy (full_name),
          assigned_to (full_name)
        `
        )
        .eq("assigned_to", user.id)
        .order("sla_deadline", { ascending: true });

      if (issueError) {
        console.error(issueError);
        setIsLoading(false);
        return;
      }

      const issuesWithCoords: Issue[] = (issueData || []).map((i) => {
        const status = i.status as "pending" | "in_progress" | "resolved";
        return {
          ...i,
          coordinates: i.coordinates ? JSON.parse(i.coordinates) : null,
          reported_by: Array.isArray(i.reported_by)
            ? i.reported_by[0] ?? null
            : null,
          assigned_to: Array.isArray(i.assigned_to)
            ? i.assigned_to[0] ?? null
            : null,
          status,
        };
      });

      setIssues(issuesWithCoords);

      if (issuesWithCoords.length > 0 && !selectedIssueId) {
        setSelectedIssueId(issuesWithCoords[0].id);
      }

      setIsLoading(false);
    };

    fetchData();

    // === REALTIME: ISSUES ===
    const issueChannel = supabase
      .channel("worker_issues")
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "issues",
          filter: `assigned_to=eq.${user.id}`,
        },
        (payload) => {
          const newIssue = payload.new as {
            id: string;
            title: string;
            description: string | null;
            category: string | null;
            priority: string | null;
            location: string | null;
            coordinates: string | null;
            status: string;
            reported_at: string;
            sla_deadline: string | null;
            reported_by?: { full_name: string }[] | null;
            assigned_to?: { full_name: string }[] | null;
          };

          const status = newIssue.status as
            | "pending"
            | "in_progress"
            | "resolved";

          const formatted: Issue = {
            ...newIssue,
            coordinates: newIssue.coordinates
              ? JSON.parse(newIssue.coordinates)
              : null,
            reported_by: Array.isArray(newIssue.reported_by)
              ? newIssue.reported_by[0] ?? null
              : null,
            assigned_to: Array.isArray(newIssue.assigned_to)
              ? newIssue.assigned_to[0] ?? null
              : null,
            status,
          };

          if (payload.eventType === "INSERT") {
            setIssues((cur) => [formatted, ...cur]);
          } else if (payload.eventType === "UPDATE") {
            setIssues((cur) =>
              cur.map((i) => (i.id === formatted.id ? formatted : i))
            );
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(issueChannel);
    };
  }, [user, selectedIssueId]);

  // === FETCH UPDATES FOR SELECTED ISSUE ===
  useEffect(() => {
    if (!selectedIssueId) return;

    const fetchUpdates = async () => {
      const { data, error } = await supabase
        .from("issue_updates")
        .select(
          `
          id,
          issue_id,
          user_id,
          message,
          created_at,
          user:users (full_name)
        `
        )
        .eq("issue_id", selectedIssueId)
        .order("created_at", { ascending: true });

      if (error) {
        console.error(error);
        return;
      }

      const formatted: IssueUpdate[] = (data || []).map((u) => ({
        ...u,
        user: Array.isArray(u.user) ? u.user[0] ?? null : null,
      }));

      setUpdates(formatted);
    };

    fetchUpdates();

    // === REALTIME: UPDATES ===
    const updateChannel = supabase
      .channel(`updates_${selectedIssueId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "issue_updates",
          filter: `issue_id=eq.${selectedIssueId}`,
        },
        (payload) => {
          const newUpdate = payload.new as {
            id: string;
            issue_id: string;
            user_id: string;
            message: string;
            created_at: string;
          };

          supabase
            .from("users")
            .select("full_name")
            .eq("id", newUpdate.user_id)
            .single()
            .then(({ data }) => {
              const userInfo = data ? { full_name: data.full_name } : null;
              setUpdates((cur) => [...cur, { ...newUpdate, user: userInfo }]);
            });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(updateChannel);
    };
  }, [selectedIssueId]);

  // === ADD UPDATE ===
  const addUpdate = async () => {
    if (!newUpdate.trim() || !selectedIssueId || !user?.id) return;

    const { error } = await supabase.from("issue_updates").insert({
      issue_id: selectedIssueId,
      user_id: user.id,
      message: newUpdate,
    });

    if (error) {
      alert("Failed to add update: " + error.message);
    } else {
      setNewUpdate("");
    }
  };

  // === DIRECTIONS ===
  const getDirections = (coords: { lat: number; lng: number }) => {
    const url = `https://www.google.com/maps/dir/?api=1&destination=${coords.lat},${coords.lng}`;
    window.open(url, "_blank");
  };

  const selectedIssue = issues.find((i) => i.id === selectedIssueId);

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-lg text-gray-600">Please log in as a worker.</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-8 h-8 bg-orange-600 rounded-lg flex items-center justify-center">
                <MapPin className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-semibold text-gray-900">
                Field Worker Portal
              </h1>
            </div>
            <Button variant="ghost" size="sm">
              <Bell className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Hello, {user.user_metadata?.full_name || "Worker"}
          </h2>
          <p className="text-gray-600">Manage your field assignments</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Issue List */}
          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle>Assigned Tasks</CardTitle>
                <CardDescription>Click to view details</CardDescription>
              </CardHeader>
              <CardContent>
                {isLoading ? (
                  <p className="text-center py-8 text-gray-500">Loading...</p>
                ) : issues.length === 0 ? (
                  <p className="text-center py-8 text-gray-500">
                    No tasks assigned.
                  </p>
                ) : (
                  <div className="space-y-4">
                    {issues.map((issue) => (
                      <div
                        key={issue.id}
                        className={`border rounded-lg p-4 cursor-pointer transition-colors ${
                          selectedIssueId === issue.id
                            ? "bg-orange-50 border-orange-200"
                            : "hover:bg-gray-50"
                        }`}
                        onClick={() => setSelectedIssueId(issue.id)}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-2">
                              {getStatusIcon(issue.status)}
                              <h3 className="font-semibold text-gray-900">
                                {issue.title}
                              </h3>
                              <Badge className={getStatusColor(issue.status)}>
                                {issue.status.replace("_", " ")}
                              </Badge>
                            </div>
                            <p className="text-gray-600 mb-2">
                              {issue.description}
                            </p>
                            <div className="flex flex-wrap gap-4 text-sm text-gray-500">
                              <span className="flex items-center gap-1">
                                <MapPin className="w-3 h-3" />
                                {issue.location}
                              </span>
                              {issue.sla_deadline && (
                                <span className="flex items-center gap-1">
                                  <Calendar className="w-3 h-3" />
                                  {new Date(
                                    issue.sla_deadline
                                  ).toLocaleDateString()}
                                </span>
                              )}
                            </div>
                          </div>
                          {issue.coordinates && (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={(e) => {
                                e.stopPropagation();
                                getDirections(issue.coordinates!);
                              }}
                            >
                              <Navigation className="w-4 h-4" />
                            </Button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Updates Panel */}
          <div>
            {selectedIssue ? (
              <Card>
                <CardHeader>
                  <CardTitle>Activity Log</CardTitle>
                  <CardDescription>{selectedIssue.title}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="max-h-96 overflow-y-auto space-y-3">
                    {updates.length === 0 ? (
                      <p className="text-center text-gray-500 py-8">
                        No updates yet.
                      </p>
                    ) : (
                      updates.map((upd) => (
                        <div key={upd.id} className="flex gap-3">
                          <Avatar className="w-8 h-8">
                            <AvatarFallback>
                              {upd.user?.full_name?.[0] || "W"}
                            </AvatarFallback>
                          </Avatar>
                          <div className="flex-1">
                            <p className="text-sm font-medium">
                              {upd.user?.full_name || "Worker"}
                            </p>
                            <p className="text-sm text-gray-600">
                              {upd.message}
                            </p>
                            <p className="text-xs text-gray-400">
                              {new Date(upd.created_at).toLocaleString()}
                            </p>
                          </div>
                        </div>
                      ))
                    )}
                  </div>

                  <div className="border-t pt-4">
                    <Textarea
                      placeholder="Add field note..."
                      value={newUpdate}
                      onChange={(e) => setNewUpdate(e.target.value)}
                      rows={3}
                    />
                    <Button
                      className="mt-2 w-full"
                      onClick={addUpdate}
                      disabled={!newUpdate.trim()}
                    >
                      <MessageSquare className="w-4 h-4 mr-2" />
                      Add Update
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-8 text-center">
                  <p className="text-gray-600">Select a task to view updates</p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
