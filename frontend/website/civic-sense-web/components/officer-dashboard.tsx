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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  MapPin,
  Bell,
  LogOut,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  XCircle,
  TrendingUp,
  Search,
  BarChart3,
  Map,
  AlertTriangle,
} from "lucide-react";
import { useAuth } from "@/hook/use-auth";

// Mock data for all issues in the system
const mockAllIssues = [
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
    assignedOfficer: "Officer Johnson",
    slaStatus: "on_time",
  },
  {
    id: "2",
    title: "Broken Street Light",
    description: "Street light not working on Oak Avenue",
    status: "resolved",
    priority: "medium",
    category: "lighting",
    reportedAt: "2024-01-10",
    location: "456 Oak Ave",
    reportedBy: "Jane Smith",
    assignedOfficer: "Officer Smith",
    slaStatus: "completed",
  },
  {
    id: "3",
    title: "Graffiti on Building",
    description: "Vandalism on community center wall",
    status: "pending",
    priority: "low",
    category: "vandalism",
    reportedAt: "2024-01-20",
    location: "789 Community Dr",
    reportedBy: "Mike Wilson",
    slaStatus: "overdue",
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
    assignedOfficer: "Officer Davis",
    slaStatus: "urgent",
  },
  {
    id: "5",
    title: "Noise Complaint",
    description: "Construction noise during restricted hours",
    status: "pending",
    priority: "medium",
    category: "noise",
    reportedAt: "2024-01-21",
    location: "654 Quiet Ave",
    reportedBy: "Bob Brown",
    slaStatus: "on_time",
  },
];

const mockOfficers = [
  {
    id: "1",
    name: "Officer Johnson",
    department: "Public Works",
    activeIssues: 3,
  },
  { id: "2", name: "Officer Smith", department: "Utilities", activeIssues: 2 },
  {
    id: "3",
    name: "Officer Davis",
    department: "Emergency Services",
    activeIssues: 1,
  },
  {
    id: "4",
    name: "Officer Wilson",
    department: "Parks & Recreation",
    activeIssues: 0,
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

const getSlaColor = (slaStatus: string) => {
  switch (slaStatus) {
    case "completed":
      return "bg-green-100 text-green-800";
    case "on_time":
      return "bg-blue-100 text-blue-800";
    case "urgent":
      return "bg-orange-100 text-orange-800";
    case "overdue":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

export function OfficerDashboard() {
  const { user } = useAuth();
  const [issues, setIssues] = useState(mockAllIssues);
  const [filterStatus, setFilterStatus] = useState("all");
  const [filterPriority, setFilterPriority] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");

  const filteredIssues = issues.filter((issue) => {
    const matchesStatus =
      filterStatus === "all" || issue.status === filterStatus;
    const matchesPriority =
      filterPriority === "all" || issue.priority === filterPriority;
    const matchesSearch =
      searchTerm === "" ||
      issue.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      issue.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
      issue.reportedBy.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesStatus && matchesPriority && matchesSearch;
  });

  const assignOfficer = (issueId: string, officerId: string) => {
    const officer = mockOfficers.find((o) => o.id === officerId);
    setIssues((prev) =>
      prev.map((issue) =>
        issue.id === issueId
          ? {
              ...issue,
              assignedOfficer: officer?.name || "",
              status: "in_progress",
            }
          : issue
      )
    );
  };

  const updateIssueStatus = (issueId: string, newStatus: string) => {
    setIssues((prev) =>
      prev.map((issue) =>
        issue.id === issueId ? { ...issue, status: newStatus } : issue
      )
    );
  };

  // Statistics
  const stats = {
    total: issues.length,
    pending: issues.filter((i) => i.status === "pending").length,
    inProgress: issues.filter((i) => i.status === "in_progress").length,
    resolved: issues.filter((i) => i.status === "resolved").length,
    overdue: issues.filter((i) => i.slaStatus === "overdue").length,
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-8 h-8 bg-red-600 rounded-lg flex items-center justify-center">
                <MapPin className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-semibold text-gray-900">
                City Snap Admin
              </h1>
            </div>

            <div className="flex items-center space-x-4">
              <Button variant="ghost" size="sm">
                <Bell className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Admin Dashboard
          </h2>
          <p className="text-gray-600">
            Monitor and manage all civic issues across the city
          </p>
        </div>

        {/* Statistics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                  <BarChart3 className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.total}
                  </p>
                  <p className="text-sm text-gray-600">Total Issues</p>
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
                <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                  <CheckCircle className="w-6 h-6 text-green-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.resolved}
                  </p>
                  <p className="text-sm text-gray-600">Resolved</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                  <AlertTriangle className="w-6 h-6 text-orange-600" />
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

        <Tabs defaultValue="issues" className="space-y-6">
          <TabsList>
            <TabsTrigger value="issues">Issue Management</TabsTrigger>
            <TabsTrigger value="map">Map View</TabsTrigger>
            <TabsTrigger value="officers">Officer Management</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
            <TabsTrigger value="audit">Audit & Security</TabsTrigger>
          </TabsList>

          <TabsContent value="issues">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>All Issues</CardTitle>
                    <CardDescription>
                      Manage and assign civic issues to officers
                    </CardDescription>
                  </div>
                  <div className="flex space-x-2">
                    <div className="relative">
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                      <Input
                        placeholder="Search issues..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="pl-10 w-64"
                      />
                    </div>
                    <Select
                      value={filterStatus}
                      onValueChange={setFilterStatus}
                    >
                      <SelectTrigger className="w-32">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">All Status</SelectItem>
                        <SelectItem value="pending">Pending</SelectItem>
                        <SelectItem value="in_progress">In Progress</SelectItem>
                        <SelectItem value="resolved">Resolved</SelectItem>
                      </SelectContent>
                    </Select>
                    <Select
                      value={filterPriority}
                      onValueChange={setFilterPriority}
                    >
                      <SelectTrigger className="w-32">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">All Priority</SelectItem>
                        <SelectItem value="critical">Critical</SelectItem>
                        <SelectItem value="high">High</SelectItem>
                        <SelectItem value="medium">Medium</SelectItem>
                        <SelectItem value="low">Low</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {filteredIssues.map((issue) => (
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
                            <Badge className={getSlaColor(issue.slaStatus)}>
                              {issue.slaStatus.replace("_", " ")}
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
                              <span>{issue.reportedAt}</span>
                            </span>
                            <span>Reported by: {issue.reportedBy}</span>
                            {issue.assignedOfficer && (
                              <span>Assigned to: {issue.assignedOfficer}</span>
                            )}
                          </div>
                        </div>
                        <div className="flex space-x-2 ml-4">
                          {!issue.assignedOfficer && (
                            <Select
                              onValueChange={(value) =>
                                assignOfficer(issue.id, value)
                              }
                            >
                              <SelectTrigger className="w-40">
                                <SelectValue placeholder="Assign Officer" />
                              </SelectTrigger>
                              <SelectContent>
                                {mockOfficers.map((officer) => (
                                  <SelectItem
                                    key={officer.id}
                                    value={officer.id}
                                  >
                                    {officer.name} ({officer.activeIssues}{" "}
                                    active)
                                  </SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          )}
                          <Select
                            value={issue.status}
                            onValueChange={(value) =>
                              updateIssueStatus(issue.id, value)
                            }
                          >
                            <SelectTrigger className="w-32">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="pending">Pending</SelectItem>
                              <SelectItem value="in_progress">
                                In Progress
                              </SelectItem>
                              <SelectItem value="resolved">Resolved</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="map">
            <Card>
              <CardHeader>
                <CardTitle>Map View</CardTitle>
                <CardDescription>
                  Geographic visualization of all reported issues
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-96 bg-gray-100 rounded-lg flex items-center justify-center">
                  <div className="text-center">
                    <Map className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-600">
                      Interactive map would be displayed here
                    </p>
                    <p className="text-sm text-gray-500">
                      Showing {filteredIssues.length} issues on the map
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="officers">
            <Card>
              <CardHeader>
                <CardTitle>Officer Management</CardTitle>
                <CardDescription>
                  Manage officer assignments and workload
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  {mockOfficers.map((officer) => (
                    <Card key={officer.id}>
                      <CardContent className="p-4">
                        <div className="flex items-center space-x-3">
                          <Avatar>
                            <AvatarFallback>
                              {officer.name.split(" ")[1]?.charAt(0)}
                            </AvatarFallback>
                          </Avatar>
                          <div className="flex-1">
                            <h3 className="font-semibold text-gray-900">
                              {officer.name}
                            </h3>
                            <p className="text-sm text-gray-600">
                              {officer.department}
                            </p>
                            <div className="flex items-center space-x-2 mt-2">
                              <Badge variant="outline">
                                {officer.activeIssues} active issues
                              </Badge>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="analytics">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle>Issue Trends</CardTitle>
                  <CardDescription>
                    Monthly issue reporting trends
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="h-64 bg-gray-100 rounded-lg flex items-center justify-center">
                    <div className="text-center">
                      <TrendingUp className="w-12 h-12 text-gray-400 mx-auto mb-2" />
                      <p className="text-gray-600">
                        Chart visualization would be here
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Category Breakdown</CardTitle>
                  <CardDescription>Issues by category</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {["Roads", "Lighting", "Water", "Vandalism", "Noise"].map(
                      (category, index) => (
                        <div
                          key={category}
                          className="flex items-center justify-between"
                        >
                          <span className="text-sm font-medium">
                            {category}
                          </span>
                          <div className="flex items-center space-x-2">
                            <div className="w-24 bg-gray-200 rounded-full h-2">
                              <div
                                className="bg-blue-600 h-2 rounded-full"
                                style={{ width: `${Math.random() * 100}%` }}
                              />
                            </div>
                            <span className="text-sm text-gray-600">
                              {Math.floor(Math.random() * 20) + 1}
                            </span>
                          </div>
                        </div>
                      )
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
}
