from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="WorkItemSearchHit")


@_attrs_define
class WorkItemSearchHit:
    """
    Attributes:
        id (str):
        project_id (str):
        project_name (str): the OWNING board’s name. A result list spanning boards is unreadable without it, and the
            client cannot join it itself — the boards a search reaches are exactly the ones it may not have loaded.
        item_key (str): the rendered key (`ADH-42`) — already joined from the board’s prefix, because a hit crossing
            boards crosses prefixes too.
        title (str):
        status_id (str):
        updated_at (str):
        snippet (str): a plain-text excerpt of the DESCRIPTION (ts_headline, no markup). Empty-ish for a title-only or
            key hit, where the title is already the answer.
        rank (float): ts_rank over title (weight A) and description (weight B).
    """

    id: str
    project_id: str
    project_name: str
    item_key: str
    title: str
    status_id: str
    updated_at: str
    snippet: str
    rank: float
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        project_id = self.project_id

        project_name = self.project_name

        item_key = self.item_key

        title = self.title

        status_id = self.status_id

        updated_at = self.updated_at

        snippet = self.snippet

        rank = self.rank

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "projectId": project_id,
                "projectName": project_name,
                "itemKey": item_key,
                "title": title,
                "statusId": status_id,
                "updatedAt": updated_at,
                "snippet": snippet,
                "rank": rank,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        project_id = d.pop("projectId")

        project_name = d.pop("projectName")

        item_key = d.pop("itemKey")

        title = d.pop("title")

        status_id = d.pop("statusId")

        updated_at = d.pop("updatedAt")

        snippet = d.pop("snippet")

        rank = d.pop("rank")

        work_item_search_hit = cls(
            id=id,
            project_id=project_id,
            project_name=project_name,
            item_key=item_key,
            title=title,
            status_id=status_id,
            updated_at=updated_at,
            snippet=snippet,
            rank=rank,
        )

        work_item_search_hit.additional_properties = d
        return work_item_search_hit

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
