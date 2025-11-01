"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
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
  LogOut,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  XCircle,
  Navigation,
  MessageSquare,
  Timer,
  Target,
} from "lucide-react";
import { useAuth } from "@/hook/use-auth";

// Mock data for officer's assigned issues
const mockAssignedIssues = [
  {
    id: "1",
    title: "Pothole on Main Street",
    description: "Large pothole causing traffic issues",
    status: "in_progress",
    priority: "high",
    category: "roads",
    reportedAt: "2024-01-15",
    location: "123 Main St",
    reportedBy: "John Citizen",
    assignedAt: "2024-01-16",
    slaDeadline: "2024-01-18",
    coordinates: { lat: 40.7128, lng: -74.006 },
    updates: [
      {
        date: "2024-01-16",
        message: "Issue assigned to officer",
        type: "system",
      },
      {
        date: "2024-01-16",
        message: "Inspected the site, materials ordered",
        type: "officer",
      },
    ],
  },
  {
    id: "4",
    title: "Water Main Break",
    description: "Water flooding the street",
    status: "in_progress",
    priority: "critical",
    category: "water",
    reportedAt: "2024-01-22",
    location: "321 Water St",
    reportedBy: "Sarah Johnson",
    assignedAt: "2024-01-22",
    slaDeadline: "2024-01-22",
    coordinates: { lat: 40.7589, lng: -73.9851 },
    updates: [
      {
        date: "2024-01-22",
        message: "Emergency response initiated",
        type: "officer",
      },
      {
        date: "2024-01-22",
        message: "Water department contacted",
        type: "officer",
      },
    ],
  },
  {
    id: "6",
    title: "Damaged Park Bench",
    description: "Broken bench in Central Park",
    status: "pending",
    priority: "low",
    category: "parks",
    reportedAt: "2024-01-20",
    location: "Central Park, Section B",
    reportedBy: "Mike Wilson",
    assignedAt: "2024-01-21",
    slaDeadline: "2024-01-25",
    coordinates: { lat: 40.7829, lng: -73.9654 },
    updates: [
      {
        date: "2024-01-21",
        message: "Issue assigned to officer",
        type: "system",
      },
    ],
  },
];

const getStatusIcon = (status: string) => {
  switch (status) {
    case "resolved":
      return <CheckCircle className="w-4 h-4 text-green-600" />;
    case "in_progress":
      return <Clock className="w-4 h-4 text-yellow-600" />;
    case "pending":
      return <AlertCircle className="w-4 h-4 text-red-600" />;
    default:
      return <XCircle className="w-4 h-4 text-gray-600" />;
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

const getPriorityColor = (priority: string) => {
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

const getSlaStatus = (deadline: string) => {
  const now = new Date();
  const slaDate = new Date(deadline);
  const hoursLeft = (slaDate.getTime() - now.getTime()) / (1000 * 60 * 60);

  if (hoursLeft < 0)
    return {
      status: "overdue",
      color: "bg-red-100 text-red-800",
      text: "Overdue",
    };
  if (hoursLeft < 24)
    return {
      status: "urgent",
      color: "bg-orange-100 text-orange-800",
      text: "Due Soon",
    };
  return {
    status: "on_time",
    color: "bg-green-100 text-green-800",
    text: "On Time",
  };
};

export function WorkerDashboard() {
  const { user } = useAuth();
  const [issues, setIssues] = useState(mockAssignedIssues);
  const [selectedIssue, setSelectedIssue] = useState<string | null>(null);
  const [updateMessage, setUpdateMessage] = useState("");

  const updateIssueStatus = (issueId: string, newStatus: string) => {
    setIssues((prev) =>
      prev.map((issue) =>
        issue.id === issueId
          ? {
              ...issue,
              status: newStatus,
              updates: [
                ...issue.updates,
                {
                  date: new Date().toISOString().split("T")[0],
                  message: `Status updated to ${newStatus}`,
                  type: "officer" as const,
                },
              ],
            }
          : issue
      )
    );
  };

  const addUpdate = (issueId: string) => {
    if (!updateMessage.trim()) return;

    setIssues((prev) =>
      prev.map((issue) =>
        issue.id === issueId
          ? {
              ...issue,
              updates: [
                ...issue.updates,
                {
                  date: new Date().toISOString().split("T")[0],
                  message: updateMessage,
                  type: "officer" as const,
                },
              ],
            }
          : issue
      )
    );
    setUpdateMessage("");
  };

  const getDirections = (coordinates: { lat: number; lng: number }) => {
    const url = `https://www.google.com/maps/dir/?api=1&destination=${coordinates.lat},${coordinates.lng}`;
    window.open(url, "_blank");
  };

  const selectedIssueData = issues.find((issue) => issue.id === selectedIssue);

  // Statistics
  const stats = {
    total: issues.length,
    pending: issues.filter((i) => i.status === "pending").length,
    inProgress: issues.filter((i) => i.status === "in_progress").length,
    resolved: issues.filter((i) => i.status === "resolved").length,
    overdue: issues.filter(
      (i) => getSlaStatus(i.slaDeadline).status === "overdue"
    ).length,
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-8 h-8 bg-green-600 rounded-lg flex items-center justify-center">
                <MapPin className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-semibold text-gray-900">
                Civic Sense Officer
              </h1>
            </div>

            <div className="flex items-center space-x-4">
              <Button variant="ghost" size="sm">
                <Bell className="w-4 h-4" />
              </Button>

              {/* <div className="flex items-center space-x-2">
                <Avatar className="w-8 h-8">
                  <AvatarImage src={user?.avatar || "/placeholder.svg"} />
                  <AvatarFallback>{user?.name?.charAt(0)}</AvatarFallback>
                </Avatar>
                <div className="text-left">
                  <span className="text-sm font-medium text-gray-700 block">
                    {user?.name}
                  </span>
                  <span className="text-xs text-gray-500">
                    {user?.department}
                  </span>
                </div>
              </div>

              <Button variant="ghost" size="sm" onClick={logout}>
                <LogOut className="w-4 h-4" />
              </Button> */}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Welcome back
          </h2>
          <p className="text-gray-600">
            Manage your assigned issues and update their status
          </p>
        </div>

        {/* Statistics Cards */}
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
                  <p className="text-sm text-gray-600">Assigned Issues</p>
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
          {/* Issues List */}
          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle>Your Assigned Issues</CardTitle>
                <CardDescription>
                  Issues assigned to you for resolution
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {issues.map((issue) => {
                    const slaInfo = getSlaStatus(issue.slaDeadline);
                    return (
                      <div
                        key={issue.id}
                        className={`border rounded-lg p-4 cursor-pointer transition-colors ${
                          selectedIssue === issue.id
                            ? "bg-blue-50 border-blue-200"
                            : "hover:bg-gray-50"
                        }`}
                        onClick={() => setSelectedIssue(issue.id)}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-2 mb-2">
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
                              <Badge className={slaInfo.color}>
                                {slaInfo.text}
                              </Badge>
                            </div>
                            <p className="text-gray-600 mb-2">
                              {issue.description}
                            </p>
                            <div className="flex items-center space-x-4 text-sm text-gray-500">
                              <span className="flex items-center space-x-1">
                                <MapPin className="w-3 h-3" />
                                <span>{issue.location}</span>
                              </span>
                              <span className="flex items-center space-x-1">
                                <Calendar className="w-3 h-3" />
                                <span>Due: {issue.slaDeadline}</span>
                              </span>
                            </div>
                          </div>
                          <div className="flex space-x-2 ml-4">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={(e) => {
                                e.stopPropagation();
                                getDirections(issue.coordinates);
                              }}
                            >
                              <Navigation className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Issue Details */}
          <div>
            {selectedIssueData ? (
              <Card>
                <CardHeader>
                  <CardTitle>Issue Details</CardTitle>
                  <CardDescription>
                    Manage and update issue status
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <h3 className="font-semibold text-gray-900 mb-2">
                      {selectedIssueData.title}
                    </h3>
                    <p className="text-gray-600 mb-4">
                      {selectedIssueData.description}
                    </p>

                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-gray-500">Reported by:</span>
                        <span className="font-medium">
                          {selectedIssueData.reportedBy}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-500">Location:</span>
                        <span className="font-medium">
                          {selectedIssueData.location}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-500">Assigned:</span>
                        <span className="font-medium">
                          {selectedIssueData.assignedAt}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-500">SLA Deadline:</span>
                        <span className="font-medium">
                          {selectedIssueData.slaDeadline}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="border-t pt-4">
                    <h4 className="font-medium text-gray-900 mb-2">
                      Update Status
                    </h4>
                    <Select
                      value={selectedIssueData.status}
                      onValueChange={(value) =>
                        updateIssueStatus(selectedIssueData.id, value)
                      }
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
                      placeholder="Add a progress update..."
                      value={updateMessage}
                      onChange={(e) => setUpdateMessage(e.target.value)}
                      rows={3}
                    />
                    <Button
                      className="mt-2 w-full"
                      onClick={() => addUpdate(selectedIssueData.id)}
                      disabled={!updateMessage.trim()}
                    >
                      <MessageSquare className="w-4 h-4 mr-2" />
                      Add Update
                    </Button>
                  </div>

                  <div className="border-t pt-4">
                    <h4 className="font-medium text-gray-900 mb-2">
                      Progress History
                    </h4>
                    <div className="space-y-2 max-h-48 overflow-y-auto">
                      {selectedIssueData.updates.map((update, index) => (
                        <div key={index} className="text-sm">
                          <div className="flex items-center space-x-2">
                            <div
                              className={`w-2 h-2 rounded-full ${
                                update.type === "officer"
                                  ? "bg-blue-500"
                                  : "bg-gray-400"
                              }`}
                            />
                            <span className="text-gray-500">{update.date}</span>
                          </div>
                          <p className="text-gray-700 ml-4">{update.message}</p>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="border-t pt-4">
                    <Button
                      variant="outline"
                      className="w-full bg-transparent"
                      onClick={() =>
                        getDirections(selectedIssueData.coordinates)
                      }
                    >
                      <Navigation className="w-4 h-4 mr-2" />
                      Get Directions
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-8 text-center">
                  <Target className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">
                    Select an issue to view details and manage updates
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
