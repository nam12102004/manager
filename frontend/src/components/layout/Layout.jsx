import React, { useState } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';

export default function Layout({
  activeTab,
  onTabChange,
  pageTitle,
  pageSubtitle,
  onQuickAction,
  children,
}) {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <div className="app-container">
      <Sidebar
        activeTab={activeTab}
        onTabChange={onTabChange}
        collapsed={collapsed}
        onToggleCollapse={() => setCollapsed(!collapsed)}
      />
      <div className="main-content">
        <Header
          pageTitle={pageTitle}
          pageSubtitle={pageSubtitle}
          onQuickAction={onQuickAction}
        />
        <main className="page-wrapper">{children}</main>
      </div>
    </div>
  );
}
