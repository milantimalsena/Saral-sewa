import { useState, useEffect } from 'react';
import { getDashboard } from '../api';
import { Users, FileText, ClipboardList, AlertTriangle, TrendingUp, Loader2 } from 'lucide-react';
import {
  LineChart, Line, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart
} from 'recharts';

const StatCard = ({ title, value, icon: Icon, color, subtitle }) => (
  <div className="glass rounded-xl p-5 hover:scale-[1.02] transition-all duration-300 animate-fade-in group">
    <div className="flex items-start justify-between">
      <div>
        <p className="text-dashboard-text-muted text-xs font-medium uppercase tracking-wider">{title}</p>
        <p className="text-3xl font-bold text-white mt-2">{value}</p>
        {subtitle && <p className="text-xs text-dashboard-text-muted mt-1">{subtitle}</p>}
      </div>
      <div className={`w-12 h-12 rounded-xl ${color} flex items-center justify-center group-hover:scale-110 transition-transform`}>
        <Icon size={22} className="text-white" />
      </div>
    </div>
  </div>
);

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="glass rounded-lg px-3 py-2 text-sm">
        <p className="text-white font-medium">{label}</p>
        <p className="text-nepal-red">{payload[0].value} {payload[0].name || 'count'}</p>
      </div>
    );
  }
  return null;
};

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDashboard()
      .then((res) => setData(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 size={40} className="animate-spin text-nepal-red" />
      </div>
    );
  }

  if (!data) {
    return <div className="text-center text-dashboard-text-muted py-20">Failed to load dashboard data.</div>;
  }

  const stats = [
    { title: 'Total Users', value: data.total_users, icon: Users, color: 'bg-gradient-to-br from-nepal-blue to-nepal-blue-light', subtitle: 'Registered citizens' },
    { title: 'Total Documents', value: data.total_documents, icon: FileText, color: 'bg-gradient-to-br from-emerald-600 to-emerald-500', subtitle: 'All uploaded documents' },
    { title: 'Total Applications', value: data.total_applications, icon: ClipboardList, color: 'bg-gradient-to-br from-violet-600 to-violet-500', subtitle: `${data.pending_applications} pending` },
    { title: 'Expiring Documents', value: data.expiring_documents, icon: AlertTriangle, color: 'bg-gradient-to-br from-nepal-red to-nepal-red-light', subtitle: 'Within 30 days' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Dashboard Overview</h1>
          <p className="text-dashboard-text-muted text-sm mt-1">Welcome back, Admin. Here's what's happening.</p>
        </div>
        <div className="flex items-center gap-2 text-xs text-dashboard-text-muted">
          <TrendingUp size={14} className="text-emerald-400" />
          <span>Real-time data</span>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, i) => (
          <StatCard key={i} {...stat} />
        ))}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* User Growth */}
        <div className="glass rounded-xl p-6 animate-fade-in">
          <h3 className="text-white font-semibold mb-4">User Growth</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data.user_growth}>
                <defs>
                  <linearGradient id="userGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#DC143C" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#DC143C" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="month" tick={{ fill: '#94A3B8', fontSize: 12 }} />
                <YAxis tick={{ fill: '#94A3B8', fontSize: 12 }} />
                <Tooltip content={<CustomTooltip />} />
                <Area type="monotone" dataKey="count" stroke="#DC143C" strokeWidth={2} fill="url(#userGradient)" name="users" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Document Uploads */}
        <div className="glass rounded-xl p-6 animate-fade-in">
          <h3 className="text-white font-semibold mb-4">Document Uploads</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.document_uploads}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="month" tick={{ fill: '#94A3B8', fontSize: 12 }} />
                <YAxis tick={{ fill: '#94A3B8', fontSize: 12 }} />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="count" fill="#003893" radius={[6, 6, 0, 0]} name="documents" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Recent Users */}
      <div className="glass rounded-xl p-6 animate-fade-in">
        <h3 className="text-white font-semibold mb-4">Recent Users</h3>
        <div className="overflow-x-auto">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Joined</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {data.recent_users?.map((user) => (
                <tr key={user.id} className="transition-colors">
                  <td className="text-white font-medium">{user.full_name}</td>
                  <td className="text-dashboard-text-muted">{user.email}</td>
                  <td className="text-dashboard-text-muted">{user.phone || '—'}</td>
                  <td className="text-dashboard-text-muted">{new Date(user.date_joined).toLocaleDateString()}</td>
                  <td>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                      user.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-red-500/20 text-red-400'
                    }`}>
                      {user.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
