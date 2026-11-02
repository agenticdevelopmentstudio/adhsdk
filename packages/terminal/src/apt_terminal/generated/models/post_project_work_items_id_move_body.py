from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectWorkItemsIdMoveBody")


@_attrs_define
class PostProjectWorkItemsIdMoveBody:
    """Where the card goes, as the cards it lands between. `{afterId: X}` puts it directly below X, `{beforeId: X}`
    directly above X, `{afterId: null}` at the very top, `{beforeId: null}` at the very bottom. Naming neither is a 400,
    and so is nulling both — that describes a list with nothing else in it. Each neighbour must be a SIBLING (same
    project, same parent) — re-parenting is PATCH /project/work-items/{id}.

        Attributes:
            after_id (None | str | Unset): the card this one goes below (id or key); null = nothing above it
            before_id (None | str | Unset): the card this one goes above (id or key); null = nothing below it
    """

    after_id: None | str | Unset = UNSET
    before_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        after_id: None | str | Unset
        if isinstance(self.after_id, Unset):
            after_id = UNSET
        else:
            after_id = self.after_id

        before_id: None | str | Unset
        if isinstance(self.before_id, Unset):
            before_id = UNSET
        else:
            before_id = self.before_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if after_id is not UNSET:
            field_dict["afterId"] = after_id
        if before_id is not UNSET:
            field_dict["beforeId"] = before_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_after_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        after_id = _parse_after_id(d.pop("afterId", UNSET))

        def _parse_before_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        before_id = _parse_before_id(d.pop("beforeId", UNSET))

        post_project_work_items_id_move_body = cls(
            after_id=after_id,
            before_id=before_id,
        )

        post_project_work_items_id_move_body.additional_properties = d
        return post_project_work_items_id_move_body

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
