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
import {
  MapPin,
  Plus,
  Bell,
  LogOut,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  XCircle,
} from "lucide-react";
import { useAuth } from "@/hook/use-auth";
import { IssueReportForm } from "@/components/issue-report-form";

// Mock data for citizen's reported issues
const mockIssues = [
  {
    id: "1",
    title: "Pothole on Main Street",
    description: "Large pothole causing traffic issues",
    status: "in_progress",
    priority: "high",
    category: "Roads",
    reportedAt: "2024-01-15",
    location: "123 Main St",
    assignedOfficer: "Officer Johnson",
  },
  {
    id: "2",
    title: "Broken Street Light",
    description: "Street light not working on Oak Avenue",
    status: "resolved",
    priority: "medium",
    category: "Lighting",
    reportedAt: "2024-01-10",
    location: "456 Oak Ave",
    assignedOfficer: "Officer Smith",
  },
  {
    id: "3",
    title: "Graffiti on Building",
    description: "Vandalism on community center wall",
    status: "pending",
    priority: "low",
    category: "Vandalism",
    reportedAt: "2024-01-20",
    location: "789 Community Dr",
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

export default function CitizenDashboard() {
  const { user } = useAuth();
  const [showReportForm, setShowReportForm] = useState(false);
  const [reportedIssues, setReportedIssues] = useState(mockIssues);

  const handleNewIssue = (newIssue: any) => {
    setReportedIssues((prev) => [newIssue, ...prev]);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <MapPin className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-semibold text-gray-900">
                Civic Sense
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
                <span className="text-sm font-medium text-gray-700">
                  {user?.name}
                </span>
              </div> */}
              {/* 
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
            Track your reported issues and submit new ones
          </p>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Card
            className="hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setShowReportForm(true)}
          >
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                  <Plus className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">Report Issue</h3>
                  <p className="text-sm text-gray-600">
                    Submit a new civic issue
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                  <MapPin className="w-6 h-6 text-green-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">View Map</h3>
                  <p className="text-sm text-gray-600">
                    See issues in your area
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                  <Calendar className="w-6 h-6 text-purple-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">My Reports</h3>
                  <p className="text-sm text-gray-600">
                    {reportedIssues.length} active reports
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Recent Issues */}
        <Card>
          <CardHeader>
            <CardTitle>Your Reported Issues</CardTitle>
            <CardDescription>
              Track the status of issues you've reported
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {reportedIssues.map((issue) => (
                <div
                  key={issue.id}
                  className="border rounded-lg p-4 hover:bg-gray-50 transition-colors"
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
                        <Badge className={getPriorityColor(issue.priority)}>
                          {issue.priority}
                        </Badge>
                      </div>
                      <p className="text-gray-600 mb-2">{issue.description}</p>
                      <div className="flex items-center space-x-4 text-sm text-gray-500">
                        <span className="flex items-center space-x-1">
                          <MapPin className="w-3 h-3" />
                          <span>{issue.location}</span>
                        </span>
                        <span className="flex items-center space-x-1">
                          <Calendar className="w-3 h-3" />
                          <span>{issue.reportedAt}</span>
                        </span>
                        {issue.assignedOfficer && (
                          <span>Assigned to: {issue.assignedOfficer}</span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </main>

      {showReportForm && (
        <IssueReportForm
          onClose={() => setShowReportForm(false)}
          onSubmit={handleNewIssue}
        />
      )}
    </div>
  );
}
