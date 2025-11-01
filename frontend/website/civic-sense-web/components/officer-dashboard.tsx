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
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  MapPin,
  Bell,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  Navigation,
  MessageSquare,
  Timer,
  Target,
} from "lucide-react";
import { useAuth } from "@/hook/use-auth";
import { createClient } from "@/utils/supabase/client";
import type { Issue } from "@/types/issue";

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

const getPriorityColor = (priority: string | null) => {
  switch (priority) {
    case "critical":
      return "bg-red-600 text-white";
    case "high":
      return "bg-red-100 text-red-800";
    case "medium":
      return "bg-yellow-100 text-yellow-800";
    case "low":
      return "bg-green-100 text-green-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getSlaStatus = (deadline: string | null) => {
  if (!deadline) return { text: "No SLA", color: "bg-gray-100 text-gray-800" };
  const hoursLeft =
    (new Date(deadline).getTime() - Date.now()) / (1000 * 60 * 60);
  if (hoursLeft < 0)
    return { text: "Overdue", color: "bg-red-100 text-red-800" };
  if (hoursLeft < 24)
    return { text: "Due Soon", color: "bg-orange-100 text-orange-800" };
  return { text: "On Time", color: "bg-green-100 text-green-800" };
};

export function OfficerDashboard() {
  const { user } = useAuth();
  const [issues, setIssues] = useState<Issue[]>([]);
  const [selectedIssueId, setSelectedIssueId] = useState<string | null>(null);
  const [updateMessage, setUpdateMessage] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;

    const fetchIssues = async () => {
      setIsLoading(true);
      setError(null);

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
          status,
          reported_at,
          sla_deadline,
          reported_by:profiles!fk_issues_reported_by (full_name),
          assigned_to:profiles!fk_issues_assigned_to (full_name)
  `
        )
        .eq("assigned_to", user.id)
        .order("sla_deadline", { ascending: true });

      if (error) {
        console.error(error);
        setError(error.message);
        setIsLoading(false);
        return;
      }

      const formattedIssues: Issue[] = (data || []).map((i) => {
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

      setIssues(formattedIssues);
      setIsLoading(false);
    };

    fetchIssues();

    // === REALTIME: ISSUES ===
    const channel = supabase
      .channel("officer_issues")
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
            setIssues((prev) => [formatted, ...prev]);
          } else if (payload.eventType === "UPDATE") {
            setIssues((prev) =>
              prev.map((i) => (i.id === formatted.id ? formatted : i))
            );
          } else if (payload.eventType === "DELETE") {
            setIssues((prev) => prev.filter((i) => i.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  const updateStatus = async (issueId: string, status: string) => {
    const { error } = await supabase
      .from("issues")
      .update({ status })
      .eq("id", issueId);

    if (error) alert("Update failed: " + error.message);
  };

  const addUpdate = async () => {
    if (!updateMessage.trim() || !selectedIssueId || !user?.id) return;

    const { error } = await supabase.from("issue_updates").insert({
      issue_id: selectedIssueId,
      user_id: user.id,
      message: updateMessage,
    });

    if (error) alert("Failed to add update: " + error.message);
    else setUpdateMessage("");
  };

  const getDirections = (coords: { lat: number; lng: number }) => {
    window.open(
      `https://www.google.com/maps/dir/?api=1&destination=${coords.lat},${coords.lng}`,
      "_blank"
    );
  };

  const selectedIssue = issues.find((i) => i.id === selectedIssueId);
  const stats = {
    total: issues.length,
    pending: issues.filter((i) => i.status === "pending").length,
    inProgress: issues.filter((i) => i.status === "in_progress").length,
    overdue: issues.filter(
      (i) => i.sla_deadline && new Date(i.sla_deadline) < new Date()
    ).length,
  };

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-lg text-gray-600">Please log in as an officer.</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-8 h-8 bg-green-600 rounded-lg flex items-center justify-center">
                <MapPin className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-semibold text-gray-900">
                Officer Dashboard
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
            Welcome back, {user.user_metadata?.full_name || "Officer"}
          </h2>
          <p className="text-gray-600">Manage your assigned issues</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                  <Target className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.total}
                  </p>
                  <p className="text-sm text-gray-600">Total</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                  <AlertCircle className="w-6 h-6 text-red-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.pending}
                  </p>
                  <p className="text-sm text-gray-600">Pending</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                  <Clock className="w-6 h-6 text-yellow-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.inProgress}
                  </p>
                  <p className="text-sm text-gray-600">In Progress</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                  <Timer className="w-6 h-6 text-orange-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.overdue}
                  </p>
                  <p className="text-sm text-gray-600">Overdue</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle>Assigned Issues</CardTitle>
                <CardDescription>Click to view details</CardDescription>
              </CardHeader>
              <CardContent>
                {isLoading ? (
                  <p className="text-center py-8 text-gray-500">Loading...</p>
                ) : error ? (
                  <p className="text-center py-8 text-red-600">{error}</p>
                ) : issues.length === 0 ? (
                  <p className="text-center py-8 text-gray-500">
                    No issues assigned.
                  </p>
                ) : (
                  <div className="space-y-4">
                    {issues.map((issue) => {
                      const sla = getSlaStatus(issue.sla_deadline ?? "");
                      return (
                        <div
                          key={issue.id}
                          className={`border rounded-lg p-4 cursor-pointer transition-colors ${
                            selectedIssueId === issue.id
                              ? "bg-blue-50 border-blue-200"
                              : "hover:bg-gray-50"
                          }`}
                          onClick={() => setSelectedIssueId(issue.id)}
                        >
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <div className="flex flex-wrap items-center gap-2 mb-2">
                                {getStatusIcon(issue.status)}
                                <h3 className="font-semibold text-gray-900">
                                  {issue.title}
                                </h3>
                                <Badge className={getStatusColor(issue.status)}>
                                  {issue.status.replace("_", " ")}
                                </Badge>
                                <Badge
                                  className={getPriorityColor(issue.priority)}
                                >
                                  {issue.priority}
                                </Badge>
                                {sla.text !== "No SLA" && (
                                  <Badge className={sla.color}>
                                    {sla.text}
                                  </Badge>
                                )}
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
                                    Due:{" "}
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
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          <div>
            {selectedIssue ? (
              <Card>
                <CardHeader>
                  <CardTitle>Issue Details</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <h3 className="font-semibold text-gray-900 mb-2">
                      {selectedIssue.title}
                    </h3>
                    <p className="text-gray-600 mb-4">
                      {selectedIssue.description}
                    </p>
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-gray-500">Reported by:</span>
                        <span className="font-medium">
                          {selectedIssue.reported_by?.full_name || "Unknown"}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-500">Location:</span>
                        <span className="font-medium">
                          {selectedIssue.location}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-500">SLA:</span>
                        <span className="font-medium">
                          {selectedIssue.sla_deadline
                            ? new Date(
                                selectedIssue.sla_deadline
                              ).toLocaleDateString()
                            : "None"}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="border-t pt-4">
                    <h4 className="font-medium text-gray-900 mb-2">
                      Update Status
                    </h4>
                    <Select
                      value={selectedIssue.status}
                      onValueChange={(v) => updateStatus(selectedIssue.id, v)}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="pending">Pending</SelectItem>
                        <SelectItem value="in_progress">In Progress</SelectItem>
                        <SelectItem value="resolved">Resolved</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="border-t pt-4">
                    <h4 className="font-medium text-gray-900 mb-2">
                      Add Update
                    </h4>
                    <Textarea
                      placeholder="Add progress note..."
                      value={updateMessage}
                      onChange={(e) => setUpdateMessage(e.target.value)}
                      rows={3}
                    />
                    <Button
                      className="mt-2 w-full"
                      onClick={addUpdate}
                      disabled={!updateMessage.trim()}
                    >
                      <MessageSquare className="w-4 h-4 mr-2" />
                      Send Update
                    </Button>
                  </div>

                  {selectedIssue.coordinates && (
                    <div className="border-t pt-4">
                      <Button
                        variant="outline"
                        className="w-full"
                        onClick={() =>
                          getDirections(selectedIssue.coordinates!)
                        }
                      >
                        <Navigation className="w-4 h-4 mr-2" />
                        Get Directions
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-8 text-center">
                  <Target className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">
                    Select an issue to view details
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
