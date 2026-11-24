from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsConnectionsByIdBodyType1")


@_attrs_define
class PostV1IntegrationsConnectionsByIdBodyType1:
    """
    Attributes:
        gmail_label_ids (list[str] | Unset): Gmail label ids to sync (default INBOX).
        gmail_window_days (int | Unset): Days of history to sync (default 30, max 366).
        reddit_subreddits (list[str] | Unset): Subreddits to watch (name or r/name; max 50).
        reddit_keywords (list[str] | Unset): Keywords to match within watched subreddits (max 50).
        audience_ids (list[str] | Unset): Provider audience/list ids to sync contacts for (default none — roster only).
    """

    gmail_label_ids: list[str] | Unset = UNSET
    gmail_window_days: int | Unset = UNSET
    reddit_subreddits: list[str] | Unset = UNSET
    reddit_keywords: list[str] | Unset = UNSET
    audience_ids: list[str] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        gmail_label_ids: list[str] | Unset = UNSET
        if not isinstance(self.gmail_label_ids, Unset):
            gmail_label_ids = self.gmail_label_ids

        gmail_window_days = self.gmail_window_days

        reddit_subreddits: list[str] | Unset = UNSET
        if not isinstance(self.reddit_subreddits, Unset):
            reddit_subreddits = self.reddit_subreddits

        reddit_keywords: list[str] | Unset = UNSET
        if not isinstance(self.reddit_keywords, Unset):
            reddit_keywords = self.reddit_keywords

        audience_ids: list[str] | Unset = UNSET
        if not isinstance(self.audience_ids, Unset):
            audience_ids = self.audience_ids

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if gmail_label_ids is not UNSET:
            field_dict["gmail_label_ids"] = gmail_label_ids
        if gmail_window_days is not UNSET:
            field_dict["gmail_window_days"] = gmail_window_days
        if reddit_subreddits is not UNSET:
            field_dict["reddit_subreddits"] = reddit_subreddits
        if reddit_keywords is not UNSET:
            field_dict["reddit_keywords"] = reddit_keywords
        if audience_ids is not UNSET:
            field_dict["audience_ids"] = audience_ids

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        gmail_label_ids = cast(list[str], d.pop("gmail_label_ids", UNSET))

        gmail_window_days = d.pop("gmail_window_days", UNSET)

        reddit_subreddits = cast(list[str], d.pop("reddit_subreddits", UNSET))

        reddit_keywords = cast(list[str], d.pop("reddit_keywords", UNSET))

        audience_ids = cast(list[str], d.pop("audience_ids", UNSET))

        post_v1_integrations_connections_by_id_body_type_1 = cls(
            gmail_label_ids=gmail_label_ids,
            gmail_window_days=gmail_window_days,
            reddit_subreddits=reddit_subreddits,
            reddit_keywords=reddit_keywords,
            audience_ids=audience_ids,
        )

        return post_v1_integrations_connections_by_id_body_type_1
