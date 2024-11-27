create table posts (
    id bigint primary key generated by default as identity,
    title varchar(255) not null,
    content text not null,
    is_published boolean not null default false,
    created_by uuid not null references auth.users(id),
    created_at timestamp default current_timestamp
);

create table comments (
    id bigint primary key generated by default as identity,
    post_id bigint not null,
    content text not null,
    created_by uuid not null references auth.users(id),
    created_at timestamp default current_timestamp,
    foreign key (post_id) references posts(id) on delete cascade
);

alter table posts enable row level security;

create policy "Users can CRUD their own posts"
    on posts as permissive for all to authenticated
    using (created_by = auth.uid())
    with check (created_by = auth.uid());

create policy "Anyone can read published posts"
    on posts for select to authenticated, anon
    using (is_published = true);

alter table comments enable row level security;

create policy "Users can read comments on posts they can view"
    on comments for select to authenticated
    using (
        exists (
            select 1 from posts 
            where id = post_id 
            and (is_published = true or created_by = auth.uid())
        )
    );

create policy "Users can write comments on posts they can view"
    on comments for insert to authenticated
    with check (
        created_by = auth.uid()
        and exists (
            select 1 
            from posts 
            where id = post_id 
            and (is_published = true or created_by = auth.uid())
        )
    );