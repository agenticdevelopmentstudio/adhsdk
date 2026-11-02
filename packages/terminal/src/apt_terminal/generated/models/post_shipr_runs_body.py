from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_shipr_runs_body_environments_item import PostShiprRunsBodyEnvironmentsItem
from ..models.post_shipr_runs_body_operation import PostShiprRunsBodyOperation
from ..models.post_shipr_runs_body_scope_kind import PostShiprRunsBodyScopeKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_shipr_runs_body_options import PostShiprRunsBodyOptions


T = TypeVar("T", bound="PostShiprRunsBody")


@_attrs_define
class PostShiprRunsBody:
    """
    Attributes:
        operation (PostShiprRunsBodyOperation):
        scope_kind (PostShiprRunsBodyScopeKind):
        scope_id (None | str | Unset): The mirror, dev repo or folder id. Null (or absent) for scopeKind=all.
        environments (list[PostShiprRunsBodyEnvironmentsItem] | Unset): Which environments a deploy walks, in pipeline
            order. Ignored by every other operation; required (non-empty) by deploy.
        options (PostShiprRunsBodyOptions | Unset): Per-operation arguments. Read defensively; unknown keys are ignored.
    """

    operation: PostShiprRunsBodyOperation
    scope_kind: PostShiprRunsBodyScopeKind
    scope_id: None | str | Unset = UNSET
    environments: list[PostShiprRunsBodyEnvironmentsItem] | Unset = UNSET
    options: PostShiprRunsBodyOptions | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        operation = self.operation.value

        scope_kind = self.scope_kind.value

        scope_id: None | str | Unset
        if isinstance(self.scope_id, Unset):
            scope_id = UNSET
        else:
            scope_id = self.scope_id

        environments: list[str] | Unset = UNSET
        if not isinstance(self.environments, Unset):
            environments = []
            for environments_item_data in self.environments:
                environments_item = environments_item_data.value
                environments.append(environments_item)

        options: dict[str, Any] | Unset = UNSET
        if not isinstance(self.options, Unset):
            options = self.options.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "operation": operation,
                "scopeKind": scope_kind,
            }
        )
        if scope_id is not UNSET:
            field_dict["scopeId"] = scope_id
        if environments is not UNSET:
            field_dict["environments"] = environments
        if options is not UNSET:
            field_dict["options"] = options

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_shipr_runs_body_options import PostShiprRunsBodyOptions

        d = dict(src_dict)
        operation = PostShiprRunsBodyOperation(d.pop("operation"))

        scope_kind = PostShiprRunsBodyScopeKind(d.pop("scopeKind"))

        def _parse_scope_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        scope_id = _parse_scope_id(d.pop("scopeId", UNSET))

        _environments = d.pop("environments", UNSET)
        environments: list[PostShiprRunsBodyEnvironmentsItem] | Unset = UNSET
        if _environments is not UNSET:
            environments = []
            for environments_item_data in _environments:
                environments_item = PostShiprRunsBodyEnvironmentsItem(environments_item_data)

                environments.append(environments_item)

        _options = d.pop("options", UNSET)
        options: PostShiprRunsBodyOptions | Unset
        if isinstance(_options, Unset):
            options = UNSET
        else:
            options = PostShiprRunsBodyOptions.from_dict(_options)

        post_shipr_runs_body = cls(
            operation=operation,
            scope_kind=scope_kind,
            scope_id=scope_id,
            environments=environments,
            options=options,
        )

        post_shipr_runs_body.additional_properties = d
        return post_shipr_runs_body

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
